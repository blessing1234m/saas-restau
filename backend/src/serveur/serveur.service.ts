import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';
import { CreatePublicCommandeDto } from './dto/public-commande.dto';

@Injectable()
export class ServeurService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
  ) {}

  // Convert image data to base64 data URI
  private convertImageToBase64(imageBuffer: Buffer, mimeType: string): string {
    if (!imageBuffer) return '';
    const base64 = imageBuffer.toString('base64');
    return `data:${mimeType || 'image/jpeg'};base64,${base64}`;
  }

  // Transform category to include base64 image
  private transformCategorie(categorie: any): any {
    if (!categorie) return categorie;
    return {
      ...categorie,
      photoAffichage: categorie.photoAffichage
        ? this.convertImageToBase64(
            categorie.photoAffichage,
            categorie.photoTypeContenu || 'image/jpeg',
          )
        : null,
    };
  }

  // Transform plat images to base64
  private transformPlat(plat: any): any {
    if (!plat) return plat;
    return {
      ...plat,
      images: (plat.images || []).map((img) => ({
        ...img,
        donnees: img.donnees
          ? this.convertImageToBase64(img.donnees, img.typeContenu || 'image/jpeg')
          : null,
      })),
    };
  }

  // Transform menu data
  private transformMenu(menu: any): any {
    if (!menu) return menu;
    return {
      ...menu,
      etablissement: menu.etablissement
        ? {
            ...menu.etablissement,
            logoAffichage: menu.etablissement.logoAffichage
              ? this.convertImageToBase64(
                  menu.etablissement.logoAffichage,
                  menu.etablissement.logoTypeContenu || 'image/jpeg',
                )
              : null,
            banniereAffichage: menu.etablissement.banniereAffichage
              ? this.convertImageToBase64(
                  menu.etablissement.banniereAffichage,
                  menu.etablissement.banniereTypeContenu || 'image/jpeg',
                )
              : null,
          }
        : null,
      categories: (menu.categories || []).map((cat) => ({
        ...this.transformCategorie(cat),
        plats: (cat.plats || []).map((plat) => this.transformPlat(plat)),
      })),
    };
  }

  private escapeHtml(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  async creerCommandePublic(
    sousRestaurantId: string,
    dto: CreatePublicCommandeDto,
  ) {
    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
      include: { etablissement: true },
    });

    if (!sousRestaurant || !sousRestaurant.estActif || !sousRestaurant.etablissement?.estActif) {
      throw new NotFoundException('Menu non disponible');
    }

    const table = (await this.prisma.table.findUnique({
      where: { id: dto.tableId },
    })) as any;

    if (!table || !table.estActive || table.sousRestaurantId !== sousRestaurantId) {
      throw new BadRequestException('Table invalide');
    }

    if (!table.tokenPublic || table.tokenPublic !== dto.tableToken) {
      throw new BadRequestException('Token de table invalide');
    }

    if (!dto.items?.length) {
      throw new BadRequestException('Panier vide');
    }

    const plats = await this.prisma.plat.findMany({
      where: {
        id: { in: dto.items.map((i) => i.platId) },
        estActif: true,
      },
      include: {
        categorie: true,
      },
    });

    if (plats.length !== dto.items.length) {
      throw new BadRequestException('Un ou plusieurs plats sont invalides');
    }

    for (const plat of plats) {
      if (plat.categorie.sousRestaurantId !== sousRestaurantId) {
        throw new BadRequestException(`Le plat ${plat.nom} n'appartient pas à ce menu`);
      }
    }

    const serveurFallback = await this.prisma.serveur.findFirst({
      where: {
        sousRestaurantId,
        utilisateur: { estActif: true },
      },
      orderBy: { createdAt: 'asc' },
      include: { utilisateur: true },
    });

    if (!serveurFallback) {
      throw new BadRequestException(
        'Aucun serveur/tablette actif configuré pour recevoir les commandes de ce sous-restaurant',
      );
    }

    let totalCommande = 0;
    const itemsData = dto.items.map((item) => {
      const plat = plats.find((p) => p.id === item.platId)!;
      const sousTotal = plat.prix * item.quantite;
      totalCommande += sousTotal;
      return {
        platId: item.platId,
        quantite: item.quantite,
        prixUnitaire: plat.prix,
        sousTotal,
      };
    });

    const commande = await this.prisma.commande.create({
      data: {
        tableId: table.id,
        sousRestaurantId,
        serveurId: serveurFallback.id,
        notes: dto.notes?.trim() || null,
        totalCommande,
        items: {
          create: itemsData,
        },
      },
      include: {
        table: true,
        items: {
          include: {
            plat: true,
          },
        },
      },
    });

    return {
      id: commande.id,
      statut: commande.statut,
      totalCommande: commande.totalCommande,
      createdAt: commande.createdAt,
      table: {
        id: commande.table.id,
        numero: commande.table.numero,
      },
      items: commande.items.map((it) => ({
        platId: it.platId,
        nom: it.plat.nom,
        quantite: it.quantite,
        prixUnitaire: it.prixUnitaire,
        sousTotal: it.sousTotal,
      })),
    };
  }

  private async obtenirEtablissementId(utilisateurId: string): Promise<string> {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    return serveur.etablissementId;
  }

  private async obtenirServeur(utilisateurId: string) {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
      include: {
        sousRestaurant: true,
      },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    if (!serveur.sousRestaurant) {
      throw new ForbiddenException('Aucun sous-restaurant assigné à ce serveur');
    }

    return serveur;
  }

  async obtenirEtablissementDuServeur(utilisateurId: string) {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
      include: {
        etablissement: true,
      },
    });

    if (!serveur) {
      throw new NotFoundException('Serveur non trouvé');
    }

    return serveur.etablissement;
  }

  async obtenirSousRestaurantDuServeur(utilisateurId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);
    return serveur.sousRestaurant;
  }

  async obtenirSousRestaurants(utilisateurId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Le serveur ne voit que son sous-restaurant assigné
    return [serveur.sousRestaurant];
  }

  async obtenirMenu(utilisateurId: string, sousRestaurantId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
      include: {
        categories: {
          where: { estActive: true },
          include: {
            plats: {
              where: { estActif: true },
              include: {
                images: {
                  orderBy: { ordre: 'asc' },
                },
              },
            },
          },
          orderBy: { ordre: 'asc' },
        },
      },
    });

    if (!sousRestaurant) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    return this.transformMenu(sousRestaurant);
  }

  async obtenirMenuPublic(sousRestaurantId: string) {
    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
      include: {
        etablissement: true,
        categories: {
          where: { estActive: true },
          include: {
            plats: {
              where: { estActif: true },
              include: {
                images: {
                  orderBy: { ordre: 'asc' },
                },
              },
              orderBy: { nom: 'asc' },
            },
          },
          orderBy: { ordre: 'asc' },
        },
      },
    });

    if (!sousRestaurant || !sousRestaurant.estActif) {
      throw new NotFoundException('Menu non disponible');
    }

    if (!sousRestaurant.etablissement?.estActif) {
      throw new NotFoundException('Etablissement inactif');
    }

    return this.transformMenu(sousRestaurant);
  }

  async genererMenuPublicHtml(sousRestaurantId: string): Promise<string> {
    const menu = await this.obtenirMenuPublic(sousRestaurantId);
    const etablissement = menu.etablissement?.nom
      ? this.escapeHtml(menu.etablissement.nom)
      : 'Restaurant';
    const logoSrc =
      typeof menu.etablissement?.logoAffichage === 'string'
        ? menu.etablissement.logoAffichage
        : '';
    const banniereSrc =
      typeof menu.etablissement?.banniereAffichage === 'string'
        ? menu.etablissement.banniereAffichage
        : '';
    const sousRestaurantNom = this.escapeHtml(menu.nom || 'Menu');
    const categories = menu.categories || [];
    const categoryCardsHtml = categories
      .map((cat, index) => {
        const catId = `cat-${index}`;
        const catNom = this.escapeHtml(cat.nom || 'Categorie');
        const catImage = cat.photoAffichage
          ? `<img class="cat-image" src="${cat.photoAffichage}" alt="${catNom}" loading="lazy" />`
          : '<div class="cat-image cat-image-placeholder">🍽</div>';
        const platCount = Array.isArray(cat.plats) ? cat.plats.length : 0;

        return `
          <button type="button" class="cat-card" data-target="${catId}" data-name="${catNom}">
            <div class="cat-left">
              <p class="cat-title">${catNom}</p>
              <p class="cat-sub">${platCount} plat${platCount > 1 ? 's' : ''}</p>
            </div>
            ${catImage}
          </button>
        `;
      })
      .join('');

    const categoryPanelsHtml = categories
      .map((cat, index) => {
        const catId = `cat-${index}`;
        const catNom = this.escapeHtml(cat.nom || 'Categorie');
        const catDescription = cat.description
          ? `<p class="cat-description">${this.escapeHtml(cat.description)}</p>`
          : '';

        const plats = cat.plats || [];
        const platsHtml = plats
          .map((plat) => {
            const nom = this.escapeHtml(plat.nom || 'Plat');
            const prixValue = Number(plat.prix);
            const prix = Number.isFinite(prixValue)
              ? `${prixValue.toLocaleString('fr-FR')} FCFA`
              : 'Prix indisponible';
            const detailId = `${catId}-plat-${this.escapeHtml(String(plat.id || nom))}`;
            const firstImage =
              Array.isArray(plat.images) && plat.images.length > 0
                ? plat.images[0]?.donnees
                : '';
            const imageSection = firstImage
              ? `<img class="plat-thumb-image" src="${firstImage}" alt="${nom}" loading="lazy" />`
              : '<div class="plat-thumb-placeholder">Aucune image</div>';

            return `
              <button type="button" class="plat-card" data-detail="${detailId}">
                <div class="plat-thumb">
                  ${imageSection}
                </div>
                <div class="plat-content">
                  <h3>${nom}</h3>
                  <span class="plat-price">${prix}</span>
                  <span
                    class="add-to-cart"
                    data-plat-id="${plat.id}"
                    data-plat-name="${nom}"
                    data-plat-price="${Number.isFinite(prixValue) ? prixValue : 0}"
                  >
                    + Ajouter
                  </span>
                </div>
              </button>
            `;
          })
          .join('');

        const detailsHtml = plats
          .map((plat) => {
            const nom = this.escapeHtml(plat.nom || 'Plat');
            const description = plat.description
              ? `<p class="detail-description">${this.escapeHtml(plat.description)}</p>`
              : '';
            const prixValue = Number(plat.prix);
            const prix = Number.isFinite(prixValue)
              ? `${prixValue.toLocaleString('fr-FR')} FCFA`
              : 'Prix indisponible';
            const detailId = `${catId}-plat-${this.escapeHtml(String(plat.id || nom))}`;
            const imageSources = (plat.images || [])
              .map((img) => img?.donnees)
              .filter((url) => typeof url === 'string' && url.length > 0);

            const detailGallery = imageSources.length
              ? `
                <div class="detail-gallery" data-total="${imageSources.length}" data-index="0">
                  <img class="detail-main-image" src="${imageSources[0]}" alt="${nom}" loading="lazy" />
                  <div class="detail-gallery-controls">
                    <button type="button" class="gallery-btn" data-action="prev">&#x2039;</button>
                    <span class="detail-counter">1/${imageSources.length}</span>
                    <button type="button" class="gallery-btn" data-action="next">&#x203a;</button>
                  </div>
                  <div class="detail-image-sources" hidden>
                    ${imageSources.map((src) => `<span data-src="${src}"></span>`).join('')}
                  </div>
                </div>
              `
              : `
                <div class="detail-gallery detail-placeholder">
                  Aucune image
                </div>
              `;

            return `
              <section class="plat-detail-panel" id="${detailId}" hidden>
                <article class="detail-card">
                  ${detailGallery}
                  <div class="detail-content">
                    <h2>${nom}</h2>
                    <p class="detail-price">${prix}</p>
                    ${description}
                    <button
                      type="button"
                      class="detail-add-to-cart"
                      data-plat-id="${plat.id}"
                      data-plat-name="${nom}"
                      data-plat-price="${Number.isFinite(prixValue) ? prixValue : 0}"
                    >
                      Ajouter au panier
                    </button>
                  </div>
                </article>
              </section>
            `;
          })
          .join('');

        return `
          <section class="plats-panel" id="${catId}" hidden>
            <h2>${catNom}</h2>
            ${catDescription}
            <div class="plats-grid">${platsHtml || '<p class="empty">Aucun plat disponible.</p>'}</div>
          </section>
          ${detailsHtml}
        `;
      })
      .join('');

    return `
      <!doctype html>
      <html lang="fr">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width,initial-scale=1" />
          <title>${sousRestaurantNom} - Menu</title>
          <style>
            :root {
              color-scheme: light;
              --bg: #f6f7fb;
              --card: #ffffff;
              --text: #171717;
              --muted: #666;
              --brand: #0f766e;
              --brand-soft: #d8f3ef;
              --line: #e5e7eb;
            }
            * { box-sizing: border-box; }
            body {
              margin: 0;
              font-family: "Segoe UI", Tahoma, Arial, sans-serif;
              color: var(--text);
              background: radial-gradient(circle at top right, #e8faf7 0%, var(--bg) 45%);
            }
            .wrap { max-width: 980px; margin: 0 auto; padding: 24px 16px 56px; }
            .hero {
              background: #fff;
              border: 1px solid var(--line);
              border-radius: 16px;
              overflow: hidden;
              box-shadow: 0 6px 18px rgba(0, 0, 0, 0.08);
              margin-bottom: 18px;
            }
            .hero-banner {
              width: 100%;
              height: 190px;
              background: linear-gradient(135deg, #0f766e, #115e59);
              position: relative;
            }
            .hero-banner img {
              width: 100%;
              height: 100%;
              object-fit: cover;
              display: block;
            }
            .hero-body {
              position: relative;
              padding: 58px 18px 18px;
              text-align: center;
              background: #fff;
            }
            .hero-logo {
              width: 88px;
              height: 88px;
              border-radius: 50%;
              background: #f0f2f6;
              border: 4px solid #fff;
              box-shadow: 0 5px 14px rgba(0, 0, 0, 0.15);
              position: absolute;
              top: -44px;
              left: 50%;
              transform: translateX(-50%);
              overflow: hidden;
              display: flex;
              align-items: center;
              justify-content: center;
            }
            .hero-logo img {
              width: 100%;
              height: 100%;
              object-fit: cover;
            }
            .hero-title {
              margin: 0;
              font-size: 30px;
              font-weight: 800;
              color: #111827;
            }
            .hero-subtitle {
              margin: 6px 0 0;
              color: #6b7280;
              font-size: 14px;
              letter-spacing: 0.8px;
              text-transform: uppercase;
            }
            .toolbar {
              display: flex;
              align-items: center;
              gap: 10px;
              margin-bottom: 12px;
            }
            .back-btn {
              border: 0;
              background: var(--brand);
              color: #fff;
              border-radius: 10px;
              padding: 10px 12px;
              font-weight: 700;
              cursor: pointer;
            }
            .toolbar-title {
              margin: 0;
              font-size: 20px;
            }
            .cat-grid {
              display: grid;
              grid-template-columns: repeat(3, minmax(0, 1fr));
              gap: 16px;
            }
            .cat-card {
              border: 1px solid #d9d9d9;
              background: #fff;
              border-radius: 22px;
              padding: 18px 22px;
              min-height: 130px;
              box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 16px;
              width: 100%;
              text-align: left;
              cursor: pointer;
            }
            .cat-card:active { transform: scale(0.99); }
            .cat-left {
              min-width: 0;
              flex: 1;
              display: flex;
              align-items: center;
            }
            .cat-title {
              margin: 0;
              font-size: 16px;
              font-weight: 800;
              color: #1b1f24;
            }
            .cat-sub {
              display: none;
            }
            .cat-image {
              width: 96px;
              height: 96px;
              border-radius: 24px;
              object-fit: contain;
              flex-shrink: 0;
              background: #f3f4f6;
            }
            .cat-image-placeholder {
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 44px;
              color: #a1a8b3;
              background: #e6e9ef;
            }
            .plats-panel {
              background: var(--card);
              border: 1px solid var(--line);
              border-radius: 14px;
              padding: 14px;
            }
            .plats-panel h2 { margin: 0 0 6px; font-size: 21px; }
            .cat-description { margin: 0 0 14px; color: var(--muted); }
            .plats-grid {
              display: grid;
              grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
              gap: 10px;
              align-items: start;
            }
            .plat-card {
              -webkit-appearance: none;
              appearance: none;
              border: 1px solid #d9d9d9;
              border-radius: 18px;
              overflow: hidden;
              padding: 0;
              text-align: left;
              background: #ffffff;
              cursor: pointer;
              width: 50%;
              display: flex;
              flex-direction: column;
              min-height: 185px;
              box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
              transition: transform 0.12s ease, box-shadow 0.12s ease;
            }
            .plat-card:hover {
              transform: translateY(-2px);
              box-shadow: 0 10px 22px rgba(0, 0, 0, 0.12);
            }
            .plat-card:active { transform: scale(0.99); }
            .plat-thumb {
              width: 100%;
              height: 100px;
              background: #ececec;
            }
            .plat-thumb-image {
              width: 100%;
              height: 100%;
              object-fit: contain;
              display: block;
            }
            .plat-thumb-placeholder {
              width: 100%;
              height: 100%;
              display: flex;
              align-items: center;
              justify-content: center;
              color: #7b7b7b;
              font-size: 13px;
              text-align: center;
              padding: 8px;
            }
            .plat-content {
              padding: 10px;
              display: flex;
              flex-direction: column;
              justify-content: space-between;
              gap: 6px;
              min-height: 72px;
            }
            .plat-content h3 {
              margin: 0;
              font-size: 16px;
              line-height: 1.2;
              font-weight: 800;
              color: #1b1f24;
              letter-spacing: 0.1px;
            }
            .plat-price {
              font-weight: 800;
              color: #2d9cdb;
              white-space: nowrap;
              font-size: 16px;
              letter-spacing: 0.3px;
            }
            .add-to-cart {
              display: inline-flex;
              align-items: center;
              justify-content: center;
              align-self: flex-start;
              margin-top: 4px;
              padding: 4px 10px;
              border-radius: 999px;
              background: #e8f7ef;
              color: #0f766e;
              font-size: 12px;
              font-weight: 700;
              cursor: pointer;
            }
            #platDetailView {
              background: var(--card);
              border: 1px solid var(--line);
              border-radius: 14px;
              padding: 14px;
            }
            .detail-card {
              display: grid;
              grid-template-columns: 1fr;
              gap: 20px;
            }
            .detail-gallery {
              border-radius: 12px;
              overflow: hidden;
              background: #f3f4f6;
              min-height: 150px;
            }
            .detail-main-image {
              width: 100%;
              height: 200px;
              object-fit: contain;
              display: block;
            }
            .detail-gallery-controls {
              display: flex;
              align-items: center;
              justify-content: space-between;
              padding: 8px 10px;
              background: #fff;
              border-top: 1px solid var(--line);
            }
            .gallery-btn {
              border: 0;
              background: var(--brand);
              color: #fff;
              width: 28px;
              height: 28px;
              border-radius: 50%;
              cursor: pointer;
              font-size: 18px;
              line-height: 1;
            }
            .detail-counter {
              font-size: 13px;
              color: var(--muted);
              font-weight: 600;
            }
            .detail-placeholder {
              display: flex;
              align-items: center;
              justify-content: center;
              color: #777;
              font-size: 13px;
            }
            .detail-content h2 {
              margin: 0;
              font-size: 24px;
            }
            .detail-price {
              margin: 8px 0 0;
              font-size: 20px;
              font-weight: 700;
              color: var(--brand);
            }
            .detail-description {
              margin: 12px 0 0;
              color: var(--muted);
              line-height: 1.45;
            }
            .detail-add-to-cart {
              margin-top: 14px;
              border: 0;
              border-radius: 10px;
              background: var(--brand);
              color: #fff;
              font-weight: 700;
              padding: 10px 12px;
              cursor: pointer;
            }
            .cart-bar {
              position: fixed;
              left: 50%;
              transform: translateX(-50%);
              bottom: 14px;
              z-index: 999;
              width: min(92vw, 680px);
              background: #111827;
              color: #fff;
              border-radius: 14px;
              box-shadow: 0 10px 28px rgba(0, 0, 0, 0.28);
              padding: 10px 12px;
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 10px;
            }
            .cart-bar[hidden] { display: none; }
            .cart-summary {
              display: flex;
              flex-direction: column;
              gap: 2px;
            }
            .cart-summary strong { font-size: 14px; }
            .cart-summary span { font-size: 12px; opacity: .82; }
            .cart-actions {
              display: flex;
              align-items: center;
              gap: 8px;
            }
            .cart-clear-btn {
              border: 1px solid #374151;
              color: #e5e7eb;
              background: transparent;
              border-radius: 10px;
              padding: 8px 10px;
              cursor: pointer;
            }
            .cart-order-btn {
              border: 0;
              background: #10b981;
              color: #052e16;
              border-radius: 10px;
              padding: 8px 12px;
              font-weight: 800;
              cursor: pointer;
            }
            .order-modal {
              position: fixed;
              inset: 0;
              z-index: 1000;
              background: rgba(15, 23, 42, 0.55);
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 14px;
            }
            .order-modal[hidden] { display: none; }
            .order-card {
              width: min(94vw, 560px);
              max-height: 88vh;
              overflow: auto;
              border-radius: 14px;
              background: #fff;
              border: 1px solid var(--line);
              padding: 14px;
            }
            .order-list { margin: 0; padding: 0; list-style: none; display: grid; gap: 8px; }
            .order-item { display: flex; justify-content: space-between; gap: 8px; font-size: 14px; }
            .order-notes {
              width: 100%;
              border: 1px solid var(--line);
              border-radius: 10px;
              padding: 8px;
              min-height: 76px;
              resize: vertical;
              font: inherit;
            }
            .order-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 12px; }
            .order-cancel, .order-submit {
              border: 0;
              border-radius: 10px;
              padding: 9px 12px;
              font-weight: 700;
              cursor: pointer;
            }
            .order-cancel { background: #e5e7eb; color: #111827; }
            .order-submit { background: var(--brand); color: #fff; }
            .empty { color: var(--muted); margin: 0; }
            @media (max-width: 680px) {
              .hero-banner { height: 150px; }
              .hero-title { font-size: 24px; }
              .hero-logo { width: 74px; height: 74px; top: -37px; }
              .hero-body { padding-top: 46px; }
              .cat-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
              .cat-card { min-height: 114px; padding: 14px 16px; border-radius: 18px; }
              .cat-title { font-size: 14px; }
              .cat-image { width: 78px; height: 78px; border-radius: 18px; }
              .plats-grid { grid-template-columns: 1fr; }
              .plat-thumb { height: 130px; }
              .plat-content { min-height: 74px; }
              .plat-content h3 { font-size: 15px; }
              .plat-price { font-size: 15px; }
              .detail-main-image { height: 220px; }
            }
          </style>
        </head>
        <body>
          <main class="wrap">
            <header class="hero">
              <div class="hero-banner">
                ${banniereSrc
                  ? `<img src="${banniereSrc}" alt="Bannière ${etablissement}" loading="lazy" />`
                  : ''}
              </div>
              <div class="hero-body">
                <div class="hero-logo">
                  ${logoSrc
                    ? `<img src="${logoSrc}" alt="Logo ${etablissement}" loading="lazy" />`
                    : '<span>🍽</span>'}
                </div>
                <h1 class="hero-title">${sousRestaurantNom}</h1>
                <p class="hero-subtitle">${etablissement}</p>
              </div>
            </header>
            <section id="categoriesView">
              <div class="cat-grid">
                ${categoryCardsHtml || '<p class="empty">Le menu est vide pour le moment.</p>'}
              </div>
            </section>
            <section id="platsView" hidden>
              <div class="toolbar">
                <button id="backToCategories" type="button" class="back-btn">Retour</button>
                <h2 id="selectedCategoryTitle" class="toolbar-title"></h2>
              </div>
              ${categoryPanelsHtml}
            </section>
            <section id="platDetailView" hidden>
              <div class="toolbar">
                <button id="backToPlats" type="button" class="back-btn">Retour</button>
                <h2 id="selectedPlatTitle" class="toolbar-title"></h2>
              </div>
            </section>
          </main>
          <div id="cartBar" class="cart-bar" hidden>
            <div class="cart-summary">
              <strong id="cartCount">0 article</strong>
              <span id="cartTotal">0 FCFA</span>
            </div>
            <div class="cart-actions">
              <button id="cartClear" type="button" class="cart-clear-btn">Vider</button>
              <button id="cartOrder" type="button" class="cart-order-btn">Commander</button>
            </div>
          </div>
          <div id="orderModal" class="order-modal" hidden>
            <div class="order-card">
              <h3 style="margin:0 0 8px;">Votre commande</h3>
              <ul id="orderList" class="order-list"></ul>
              <p id="orderTotal" style="margin:10px 0 0;font-weight:700;"></p>
              <div style="margin-top:10px;">
                <label for="orderNotes" style="display:block;margin-bottom:6px;font-size:13px;">Notes (optionnel)</label>
                <textarea id="orderNotes" class="order-notes" placeholder="Ex: sans oignons"></textarea>
              </div>
              <div class="order-actions">
                <button id="orderCancel" type="button" class="order-cancel">Annuler</button>
                <button id="orderSubmit" type="button" class="order-submit">Valider</button>
              </div>
            </div>
          </div>
          <script>
            (function() {
              var categoriesView = document.getElementById('categoriesView');
              var platsView = document.getElementById('platsView');
              var platDetailView = document.getElementById('platDetailView');
              var backBtn = document.getElementById('backToCategories');
              var backToPlatsBtn = document.getElementById('backToPlats');
              var selectedTitle = document.getElementById('selectedCategoryTitle');
              var selectedPlatTitle = document.getElementById('selectedPlatTitle');
              var cards = document.querySelectorAll('.cat-card');
              var panels = document.querySelectorAll('.plats-panel');
              var platCards = document.querySelectorAll('.plat-card');
              var detailPanels = document.querySelectorAll('.plat-detail-panel');
              var addButtons = document.querySelectorAll('.add-to-cart, .detail-add-to-cart');
              var cartBar = document.getElementById('cartBar');
              var cartCount = document.getElementById('cartCount');
              var cartTotal = document.getElementById('cartTotal');
              var cartClear = document.getElementById('cartClear');
              var cartOrder = document.getElementById('cartOrder');
              var orderModal = document.getElementById('orderModal');
              var orderList = document.getElementById('orderList');
              var orderTotal = document.getElementById('orderTotal');
              var orderCancel = document.getElementById('orderCancel');
              var orderSubmit = document.getElementById('orderSubmit');
              var orderNotes = document.getElementById('orderNotes');

              var query = new URLSearchParams(window.location.search);
              var tableId = query.get('table') || '';
              var tableToken = query.get('t') || '';
              var cart = {};

              function formatPrice(value) {
                return Number(value || 0).toLocaleString('fr-FR') + ' FCFA';
              }

              function hideAllPanels() {
                panels.forEach(function(panel) { panel.hidden = true; });
              }

              function hideAllDetails() {
                detailPanels.forEach(function(panel) { panel.hidden = true; });
              }

              function initDetailGallery(panel) {
                if (!panel || panel.dataset.galleryReady === '1') return;
                var gallery = panel.querySelector('.detail-gallery[data-total]');
                if (!gallery) {
                  panel.dataset.galleryReady = '1';
                  return;
                }

                var sources = Array.prototype.map.call(
                  panel.querySelectorAll('.detail-image-sources [data-src]'),
                  function(node) { return node.getAttribute('data-src'); }
                ).filter(function(src) { return !!src; });

                if (!sources.length) {
                  panel.dataset.galleryReady = '1';
                  return;
                }

                var mainImage = panel.querySelector('.detail-main-image');
                var counter = panel.querySelector('.detail-counter');
                var prevBtn = panel.querySelector('.gallery-btn[data-action="prev"]');
                var nextBtn = panel.querySelector('.gallery-btn[data-action="next"]');
                var index = 0;

                function renderImage(nextIndex) {
                  if (!mainImage || !counter) return;
                  index = (nextIndex + sources.length) % sources.length;
                  mainImage.src = sources[index];
                  counter.textContent = (index + 1) + '/' + sources.length;
                }

                if (prevBtn) {
                  prevBtn.addEventListener('click', function() { renderImage(index - 1); });
                }
                if (nextBtn) {
                  nextBtn.addEventListener('click', function() { renderImage(index + 1); });
                }

                renderImage(0);
                panel.dataset.galleryReady = '1';
              }

              function refreshCartUI() {
                var entries = Object.values(cart);
                var totalQty = entries.reduce(function(acc, item) { return acc + item.quantite; }, 0);
                var totalPrice = entries.reduce(function(acc, item) { return acc + (item.prix * item.quantite); }, 0);

                if (cartCount) {
                  cartCount.textContent = totalQty + (totalQty > 1 ? ' articles' : ' article');
                }
                if (cartTotal) {
                  cartTotal.textContent = formatPrice(totalPrice);
                }
                if (cartBar) {
                  cartBar.hidden = totalQty === 0;
                }
              }

              function addToCart(platId, nom, prix) {
                if (!platId) return;
                var numericPrice = Number(prix || 0);
                if (!cart[platId]) {
                  cart[platId] = { platId: platId, nom: nom || 'Plat', prix: numericPrice, quantite: 0 };
                }
                cart[platId].quantite += 1;
                refreshCartUI();
              }

              function openOrderModal() {
                var entries = Object.values(cart);
                if (!entries.length) return;
                if (!orderList || !orderTotal || !orderModal) return;

                var totalPrice = 0;
                orderList.innerHTML = entries.map(function(item) {
                  var sousTotal = item.prix * item.quantite;
                  totalPrice += sousTotal;
                  return '<li class="order-item"><span>' + item.nom + ' x' + item.quantite + '</span><strong>' + formatPrice(sousTotal) + '</strong></li>';
                }).join('');

                orderTotal.textContent = 'Total: ' + formatPrice(totalPrice);
                orderModal.hidden = false;
              }

              async function submitOrder() {
                if (!tableId) {
                  alert('Ce QR n\\'est pas lié à une table. Régénérez un QR avec table.');
                  return;
                }

                var entries = Object.values(cart);
                if (!entries.length) return;

                var payload = {
                  tableId: tableId,
                  tableToken: tableToken,
                  items: entries.map(function(item) { return { platId: item.platId, quantite: item.quantite }; }),
                };
                if (orderNotes && orderNotes.value.trim()) {
                  payload.notes = orderNotes.value.trim();
                }

                var orderUrl = window.location.pathname.replace('/menu', '/commandes');
                var submitBtn = orderSubmit;
                if (submitBtn) {
                  submitBtn.disabled = true;
                  submitBtn.textContent = 'Envoi...';
                }

                try {
                  var response = await fetch(orderUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload),
                  });

                  var data = await response.json().catch(function() { return {}; });
                  if (!response.ok) {
                    throw new Error(data.message || 'Erreur lors de la commande');
                  }

                  alert('Commande validée. Numéro: ' + (data.id || 'N/A'));
                  cart = {};
                  if (orderNotes) orderNotes.value = '';
                  if (orderModal) orderModal.hidden = true;
                  refreshCartUI();
                } catch (error) {
                  alert(error && error.message ? error.message : 'Erreur lors de la commande');
                } finally {
                  if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Valider';
                  }
                }
              }

              cards.forEach(function(card) {
                card.addEventListener('click', function() {
                  var target = card.getAttribute('data-target');
                  var name = card.getAttribute('data-name') || '';
                  var panel = document.getElementById(target);
                  if (!panel) return;
                  hideAllPanels();
                  hideAllDetails();
                  panel.hidden = false;
                  selectedTitle.textContent = name;
                  selectedPlatTitle.textContent = '';
                  categoriesView.hidden = true;
                  platsView.hidden = false;
                  platDetailView.hidden = true;
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                });
              });

              platCards.forEach(function(card) {
                card.addEventListener('click', function() {
                  var detailId = card.getAttribute('data-detail');
                  if (!detailId) return;
                  var detailPanel = document.getElementById(detailId);
                  if (!detailPanel || !platDetailView) return;

                  hideAllDetails();
                  detailPanel.hidden = false;
                  initDetailGallery(detailPanel);

                  var contentTitle = detailPanel.querySelector('.detail-content h2');
                  selectedPlatTitle.textContent = contentTitle ? (contentTitle.textContent || '') : '';

                  platDetailView.appendChild(detailPanel);
                  categoriesView.hidden = true;
                  platsView.hidden = true;
                  platDetailView.hidden = false;
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                });
              });

              addButtons.forEach(function(button) {
                button.addEventListener('click', function(event) {
                  event.preventDefault();
                  event.stopPropagation();
                  addToCart(
                    this.getAttribute('data-plat-id') || '',
                    this.getAttribute('data-plat-name') || 'Plat',
                    Number(this.getAttribute('data-plat-price') || '0'),
                  );
                });
              });

              if (cartClear) {
                cartClear.addEventListener('click', function() {
                  cart = {};
                  refreshCartUI();
                });
              }
              if (cartOrder) {
                cartOrder.addEventListener('click', openOrderModal);
              }
              if (orderCancel && orderModal) {
                orderCancel.addEventListener('click', function() { orderModal.hidden = true; });
                orderModal.addEventListener('click', function(e) {
                  if (e.target === orderModal) orderModal.hidden = true;
                });
              }
              if (orderSubmit) {
                orderSubmit.addEventListener('click', submitOrder);
              }

              backBtn.addEventListener('click', function() {
                hideAllPanels();
                hideAllDetails();
                platsView.hidden = true;
                platDetailView.hidden = true;
                categoriesView.hidden = false;
                selectedTitle.textContent = '';
                selectedPlatTitle.textContent = '';
              });

              backToPlatsBtn.addEventListener('click', function() {
                hideAllDetails();
                platDetailView.hidden = true;
                platsView.hidden = false;
                categoriesView.hidden = true;
                selectedPlatTitle.textContent = '';
              });

              refreshCartUI();
            })();
          </script>
        </body>
      </html>
    `;
  }

  async obtenirCategories(utilisateurId: string, sousRestaurantId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const categories = await this.prisma.categorie.findMany({
      where: {
        sousRestaurantId,
        estActive: true,
      },
      orderBy: { ordre: 'asc' },
    });

    return categories.map((cat) => this.transformCategorie(cat));
  }

  async obtenirPlatsDuCategorie(
    utilisateurId: string,
    sousRestaurantId: string,
    categorieId: string,
  ) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    const plats = await this.prisma.plat.findMany({
      where: {
        categorieId,
        estActif: true,
      },
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
      orderBy: { nom: 'asc' },
    });

    return plats.map((plat) => this.transformPlat(plat));
  }

  // ========== GESTION DES MOTS DE PASSE ==========

  async changerMotDePasseServeur(
    utilisateurId: string,
    changePasswordDto: ChangePasswordDto,
  ) {
    // Récupérer le serveur et son utilisateur
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
      include: { utilisateur: true },
    });

    if (!serveur) {
      throw new NotFoundException('Serveur non trouvé');
    }

    // Vérifier l'ancien mot de passe
    const estValide = await this.authService.verifierMotDePasse(
      changePasswordDto.ancienMotDePasse,
      serveur.utilisateur.motDePasse,
    );

    if (!estValide) {
      throw new BadRequestException('L\'ancien mot de passe est incorrect');
    }

    // Hasher le nouveau mot de passe
    const nouveauMotDePasseHash = await this.authService.hasherMotDePasse(
      changePasswordDto.nouveauMotDePasse,
    );

    // Mettre à jour le mot de passe
    await this.prisma.utilisateur.update({
      where: { id: utilisateurId },
      data: { motDePasse: nouveauMotDePasseHash },
    });

    return { message: 'Mot de passe changé avec succès' };
  }
}




