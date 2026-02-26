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

        const platsHtml = (cat.plats || [])
          .map((plat) => {
            const nom = this.escapeHtml(plat.nom || 'Plat');
            const description = plat.description
              ? `<p class="plat-description">${this.escapeHtml(plat.description)}</p>`
              : '';
            const prixValue = Number(plat.prix);
            const prix = Number.isFinite(prixValue)
              ? `${prixValue.toLocaleString('fr-FR')} FCFA`
              : 'Prix indisponible';
            // build markup for all available images (horizontal scroll if more than one)
            let imagesSection: string;
            if (plat.images && plat.images.length > 0) {
              const imgsHtml = plat.images
                .map((img, idx) => {
                  const url = img.donnees;
                  return url
                    ? `<img class="plat-image clickable-image" data-fullscreen-src="${url}" data-image-index="${idx}" src="${url}" alt="${nom}" loading="lazy" style="cursor: pointer;" />`
                    : '';
                })
                .join('');
              imagesSection = `<div class="plat-images">${imgsHtml}</div>`;
            } else {
              imagesSection =
                '<div class="plat-image plat-placeholder">Aucune image</div>';
            }

            return `
              <article class="plat">
                ${imagesSection}
                <div class="plat-content">
                  <div class="plat-header">
                    <h3>${nom}</h3>
                    <span class="plat-price">${prix}</span>
                  </div>
                  ${description}
                </div>
              </article>
            `;
          })
          .join('');

        return `
          <section class="plats-panel" id="${catId}" hidden>
            <h2>${catNom}</h2>
            ${catDescription}
            <div class="plats">${platsHtml || '<p class="empty">Aucun plat disponible.</p>'}</div>
          </section>
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
              grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
              gap: 12px;
            }
            .cat-card {
              border: 1px solid var(--line);
              background: #fff;
              border-radius: 16px;
              padding: 14px;
              min-height: 112px;
              box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 12px;
              width: 100%;
              text-align: left;
              cursor: pointer;
            }
            .cat-card:active { transform: scale(0.99); }
            .cat-left { min-width: 0; }
            .cat-title {
              margin: 0;
              font-size: 24px;
              font-weight: 800;
              color: #0f1f17;
            }
            .cat-sub {
              margin: 6px 0 0;
              font-size: 13px;
              color: var(--muted);
            }
            .cat-image {
              width: 84px;
              height: 84px;
              border-radius: 22px;
              object-fit: cover;
              flex-shrink: 0;
              background: var(--brand-soft);
            }
            .cat-image-placeholder {
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 30px;
            }
            .plats-panel {
              background: var(--card);
              border: 1px solid var(--line);
              border-radius: 14px;
              padding: 14px;
            }
            .plats-panel h2 { margin: 0 0 6px; font-size: 21px; }
            .cat-description { margin: 0 0 14px; color: var(--muted); }
            .plats { display: grid; grid-template-columns: 1fr; gap: 12px; }
            .plat {
              display: grid;
              grid-template-columns: 110px 1fr;
              gap: 12px;
              border: 1px solid var(--line);
              border-radius: 12px;
              overflow: hidden;
              background: #fff;
            }
            .plat-image {
              width: 100%;
              height: 100%;
              min-height: 104px;
              object-fit: cover;
              background: #f3f4f6;
            }
            /* container for multiple photos, scrollable horizontally */
            .plat-images {
              display: flex;
              gap: 4px;
              overflow-x: auto;
            }
            .plat-images .plat-image {
              flex: 0 0 auto;
              width: 110px;
              height: 100%;
            }
            .plat-placeholder {
              display: flex;
              align-items: center;
              justify-content: center;
              min-height: 104px;
              background: #f3f4f6;
              color: #777;
              font-size: 12px;
              text-align: center;
              padding: 8px;
            }
            .plat-content { padding: 10px; }
            .plat-header {
              display: flex;
              gap: 8px;
              justify-content: space-between;
              align-items: baseline;
            }
            .plat-header h3 { margin: 0; font-size: 17px; }
            .plat-price { font-weight: 700; color: var(--brand); white-space: nowrap; }
            .plat-description { margin: 8px 0 0; color: var(--muted); line-height: 1.35; }
            .empty { color: var(--muted); margin: 0; }
            /* Modal pour les images fullscreen */
            .image-modal {
              display: none;
              position: fixed;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
              background: rgba(0, 0, 0, 0.95);
              z-index: 1000;
              justify-content: center;
              align-items: center;
              padding: 20px;
            }
            .image-modal.active {
              display: flex;
            }
            .image-modal-content {
              position: relative;
              display: flex;
              flex-direction: column;
              align-items: center;
              gap: 12px;
              max-width: 90vw;
              max-height: 90vh;
            }
            .image-modal-img {
              max-width: 100%;
              max-height: 85vh;
              object-fit: contain;
              border-radius: 8px;
            }
            .image-modal-close {
              position: absolute;
              top: 10px;
              right: 10px;
              background: rgba(255, 255, 255, 0.3);
              border: none;
              color: white;
              font-size: 28px;
              width: 40px;
              height: 40px;
              border-radius: 50%;
              cursor: pointer;
              display: flex;
              align-items: center;
              justify-content: center;
              transition: background 0.2s;
            }
            .image-modal-close:hover {
              background: rgba(255, 255, 255, 0.5);
            }
            .image-modal-counter {
              color: white;
              font-size: 14px;
              margin-top: 8px;
            }
            @media (max-width: 680px) {
              .hero h1 { font-size: 24px; }
              .cat-title { font-size: 21px; }
              .cat-image { width: 78px; height: 78px; }
              .plat { grid-template-columns: 1fr; }
              .plat-image, .plat-placeholder { min-height: 180px; }
              .image-modal-img { max-height: 80vh; }
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
          </main>
          <!-- Modal pour afficher les images en fullscreen -->
          <div id="imageModal" class="image-modal">
            <div class="image-modal-content">
              <button id="modalClose" class="image-modal-close">&times;</button>
              <img id="modalImage" class="image-modal-img" src="" alt="Image plein écran" />
              <div id="imageCounter" class="image-modal-counter"></div>
            </div>
          </div>
          <script>
            (function() {
              var categoriesView = document.getElementById('categoriesView');
              var platsView = document.getElementById('platsView');
              var backBtn = document.getElementById('backToCategories');
              var selectedTitle = document.getElementById('selectedCategoryTitle');
              var cards = document.querySelectorAll('.cat-card');
              var panels = document.querySelectorAll('.plats-panel');
              var imageModal = document.getElementById('imageModal');
              var modalImage = document.getElementById('modalImage');
              var modalClose = document.getElementById('modalClose');
              var imageCounter = document.getElementById('imageCounter');
              var clickableImages = document.querySelectorAll('.clickable-image');

              function hideAllPanels() {
                panels.forEach(function(panel) { panel.hidden = true; });
              }

              // Récupérer toutes les images associées au parent de l'image cliquée
              function getImageGroup(element) {
                var imageContainer = element.closest('.plat-images') || element.parentElement;
                return imageContainer.querySelectorAll('.plat-image[data-fullscreen-src]');
              }

              // Afficher la modal avec une image
              function showImageModal(imageElement, imageIndex) {
                var imageGroup = getImageGroup(imageElement);
                var src = imageElement.getAttribute('data-fullscreen-src');
                modalImage.src = src;
                imageModal.classList.add('active');
                
                // Mettre à jour le compteur
                if (imageGroup.length > 1) {
                  imageCounter.textContent = (imageIndex + 1) + ' / ' + imageGroup.length;
                  
                  // Permettre la navigation avec les touches
                  document.currentImageGroup = imageGroup;
                  document.currentImageIndex = imageIndex;
                } else {
                  imageCounter.textContent = '';
                }
              }

              // Fermer la modal
              function closeImageModal() {
                imageModal.classList.remove('active');
                document.currentImageGroup = null;
              }

              // Gestion des clics sur les images
              clickableImages.forEach(function(img) {
                img.addEventListener('click', function(e) {
                  e.preventDefault();
                  var index = parseInt(this.getAttribute('data-image-index'), 10);
                  showImageModal(this, index);
                });
              });

              // Fermer avec le bouton
              modalClose.addEventListener('click', function() {
                closeImageModal();
              });

              // Fermer en cliquant en dehors
              imageModal.addEventListener('click', function(e) {
                if (e.target === imageModal) {
                  closeImageModal();
                }
              });

              // Navigation avec touches fléchées
              document.addEventListener('keydown', function(e) {
                if (!imageModal.classList.contains('active')) return;
                
                var imageGroup = document.currentImageGroup;
                var currentIndex = document.currentImageIndex;
                
                if (!imageGroup) return;
                
                if (e.key === 'ArrowRight') {
                  e.preventDefault();
                  var nextIndex = (currentIndex + 1) % imageGroup.length;
                  showImageModal(imageGroup[nextIndex], nextIndex);
                } else if (e.key === 'ArrowLeft') {
                  e.preventDefault();
                  var prevIndex = (currentIndex - 1 + imageGroup.length) % imageGroup.length;
                  showImageModal(imageGroup[prevIndex], prevIndex);
                } else if (e.key === 'Escape') {
                  e.preventDefault();
                  closeImageModal();
                }
              });

              // Gestion des catégories existante
              cards.forEach(function(card) {
                card.addEventListener('click', function() {
                  var target = card.getAttribute('data-target');
                  var name = card.getAttribute('data-name') || '';
                  var panel = document.getElementById(target);
                  if (!panel) return;
                  hideAllPanels();
                  panel.hidden = false;
                  selectedTitle.textContent = name;
                  categoriesView.hidden = true;
                  platsView.hidden = false;
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                });
              });

              backBtn.addEventListener('click', function() {
                hideAllPanels();
                platsView.hidden = true;
                categoriesView.hidden = false;
                selectedTitle.textContent = '';
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
