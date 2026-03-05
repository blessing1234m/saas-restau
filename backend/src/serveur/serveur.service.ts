import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';

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
              background: linear-gradient(135deg, #0f766e, #115e59);
              color: #fff;
              border-radius: 16px;
              padding: 20px;
              box-shadow: 0 12px 24px rgba(15, 118, 110, 0.22);
              margin-bottom: 18px;
            }
            .hero h1 { margin: 0 0 4px; font-size: 28px; }
            .hero p { margin: 0; opacity: .92; }
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
              font-size: 22px;
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
              object-fit: cover;
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
            .empty { color: var(--muted); margin: 0; }
            @media (max-width: 680px) {
              .hero h1 { font-size: 24px; }
              .cat-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
              .cat-card { min-height: 114px; padding: 14px 16px; border-radius: 18px; }
              .cat-title { font-size: 18px; }
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
              <p>${etablissement}</p>
              <h1>${sousRestaurantNom}</h1>
              <p>Menu en ligne</p>
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
                  prevBtn.addEventListener('click', function() {
                    renderImage(index - 1);
                  });
                }
                if (nextBtn) {
                  nextBtn.addEventListener('click', function() {
                    renderImage(index + 1);
                  });
                }

                renderImage(0);
                panel.dataset.galleryReady = '1';
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




