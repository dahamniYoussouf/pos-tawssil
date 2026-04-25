// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Mobile menu toggle
const mobileMenuToggle = document.getElementById('mobileMenuToggle');
const headerMenu = document.getElementById('headerMenu');

if (mobileMenuToggle && headerMenu) {
    const closeMenu = () => {
        headerMenu.classList.remove('is-open');
        mobileMenuToggle.classList.remove('active');
        mobileMenuToggle.setAttribute('aria-expanded', 'false');
    };

    mobileMenuToggle.addEventListener('click', () => {
        const isOpen = headerMenu.classList.toggle('is-open');
        mobileMenuToggle.classList.toggle('active', isOpen);
        mobileMenuToggle.setAttribute('aria-expanded', String(isOpen));
    });

    // Close after clicking a link
    headerMenu.addEventListener('click', (e) => {
        const link = e.target && e.target.closest ? e.target.closest('a[href^="#"]') : null;
        if (link) closeMenu();
    });

    // Close on outside click
    document.addEventListener('click', (e) => {
        if (!headerMenu.classList.contains('is-open')) return;
        if (headerMenu.contains(e.target) || mobileMenuToggle.contains(e.target)) return;
        closeMenu();
    });
}

// Scroll animations - improved with better performance
const observerOptions = {
    threshold: 0.05,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            // Use requestAnimationFrame for smoother animation
            requestAnimationFrame(() => {
                entry.target.classList.add('fade-in');
            });
            // Unobserve after animation to improve performance
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe elements for animation
document.querySelectorAll('.category-card, .dish-card, .step-card').forEach(el => {
    observer.observe(el);
});

// Special one-time animation for partner button
const partnerButton = document.getElementById('partner-btn');
const partnerSection = document.querySelector('.partner-section');

if (partnerButton && partnerSection) {
    const partnerObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !partnerButton.classList.contains('animate-in')) {
                // Delay slightly for better visual effect
                setTimeout(() => {
                    partnerButton.classList.add('animate-in');
                }, 300);
                // Unobserve after animation starts
                partnerObserver.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.3,
        rootMargin: '0px'
    });

    partnerObserver.observe(partnerSection);
}

// Registration forms (driver + restaurant)
const REGISTER_ENDPOINT = '/api/auth/register';

const DEFAULT_CATEGORY_IMAGE =
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?fm=webp&w=320&h=320&q=55&fit=crop&auto=format';

const CATEGORY_IMAGE_FALLBACKS = {
    pizza: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    burger: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    tacos: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    sandwish: 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    sandwich: 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    salad: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    salade: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    dessert: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    desserts: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    cafe: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?fm=webp&w=320&h=320&q=55&fit=crop&auto=format',
    coffee: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?fm=webp&w=320&h=320&q=55&fit=crop&auto=format'
};

const resolveCategoryImageUrl = (category) => {
    const raw = (category && category.image_url) ? String(category.image_url).trim() : '';
    if (raw) return raw;
    const slug = category && category.slug ? String(category.slug).toLowerCase() : '';
    return CATEGORY_IMAGE_FALLBACKS[slug] || DEFAULT_CATEGORY_IMAGE;
};

const sanitizePhone = (value) => String(value || '')
    .replace(/\s+/g, '')
    .replace(/^\+/, '');

const slugify = (value) => String(value || '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');

const setFormMessage = (form, message, type) => {
    const messageEl = form.querySelector('.form-message');
    if (!messageEl) {
        return;
    }
    messageEl.textContent = message || '';
    messageEl.classList.remove('success', 'error', 'show');
    if (message) {
        messageEl.classList.add(type || 'error', 'show');
    }
};

const setFormLoading = (form, isLoading) => {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
        submitBtn.disabled = isLoading;
        submitBtn.dataset.originalText = submitBtn.dataset.originalText || submitBtn.textContent;
        submitBtn.textContent = isLoading ? 'Envoi en cours...' : submitBtn.dataset.originalText;
    }
};

const cleanPayload = (payload) => {
    const cleaned = { ...payload };
    Object.keys(cleaned).forEach((key) => {
        if (cleaned[key] === '' || cleaned[key] === null || cleaned[key] === undefined) {
            delete cleaned[key];
        }
    });
    return cleaned;
};

const collectCategories = (form) => {
    const selected = Array.from(form.querySelectorAll('.category-options input[type="checkbox"]:checked'))
        .map((input) => input.value)
        .filter(Boolean);
    return Array.from(new Set(selected));
};

const buildDriverPayload = (form) => {
    return cleanPayload({
        type: 'driver',
        first_name: form.querySelector('input[name="first_name"]')?.value?.trim(),
        last_name: form.querySelector('input[name="last_name"]')?.value?.trim(),
        email: form.querySelector('input[name="email"]')?.value?.trim(),
        phone: sanitizePhone(form.querySelector('input[name="phone"]')?.value),
        password: form.querySelector('input[name="password"]')?.value,
        vehicle_type: form.querySelector('select[name="vehicle_type"]')?.value,
        vehicle_plate: form.querySelector('input[name="vehicle_plate"]')?.value?.trim(),
        license_number: form.querySelector('input[name="license_number"]')?.value?.trim(),
        device_platform: 'web',
        device_id: `landing-${Date.now()}`
    });
};

const buildRestaurantPayload = (form) => {
    return cleanPayload({
        type: 'restaurant',
        name: form.querySelector('input[name="name"]')?.value?.trim(),
        email: form.querySelector('input[name="email"]')?.value?.trim(),
        password: form.querySelector('input[name="password"]')?.value,
        phone_number: sanitizePhone(form.querySelector('input[name="phone_number"]')?.value),
        address: form.querySelector('input[name="address"]')?.value?.trim(),
        commune_id: form.querySelector('input[name="commune_id"]')?.value?.trim(),
        lat: form.querySelector('input[name="lat"]')?.value,
        lng: form.querySelector('input[name="lng"]')?.value,
        categories: collectCategories(form),
        device_platform: 'web',
        device_id: `landing-${Date.now()}`
    });
};

const restaurantLocationState = {
    map: null,
    marker: null,
    pendingLocation: null
};

let leafletAssetsPromise = null;

const loadLeafletAssets = () => {
    if (window.L) {
        return Promise.resolve(window.L);
    }

    if (leafletAssetsPromise) {
        return leafletAssetsPromise;
    }

    leafletAssetsPromise = new Promise((resolve, reject) => {
        const stylesheetHref = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        if (!document.querySelector(`link[href="${stylesheetHref}"]`)) {
            const stylesheet = document.createElement('link');
            stylesheet.rel = 'stylesheet';
            stylesheet.href = stylesheetHref;
            document.head.appendChild(stylesheet);
        }

        const existingScript = document.querySelector('script[data-leaflet-loader="1"]');
        if (existingScript) {
            existingScript.addEventListener('load', () => resolve(window.L), { once: true });
            existingScript.addEventListener('error', () => reject(new Error('Leaflet failed to load.')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        script.defer = true;
        script.dataset.leafletLoader = '1';
        script.onload = () => resolve(window.L);
        script.onerror = () => reject(new Error('Leaflet failed to load.'));
        document.body.appendChild(script);
    });

    return leafletAssetsPromise;
};

const getRestaurantLocationInputs = (form) => ({
    lat: form?.querySelector('input[name="lat"]'),
    lng: form?.querySelector('input[name="lng"]')
});

const readRestaurantLocation = (form) => {
    const { lat, lng } = getRestaurantLocationInputs(form);
    const latRaw = lat?.value;
    const lngRaw = lng?.value;

    // Empty inputs should not default to 0,0
    if (!latRaw || !lngRaw) {
        return null;
    }

    const latValue = Number.parseFloat(latRaw);
    const lngValue = Number.parseFloat(lngRaw);
    if (!Number.isFinite(latValue) || !Number.isFinite(lngValue)) {
        return null;
    }
    return { lat: latValue, lng: lngValue };
};

const formatCoordinate = (value) => Number(value).toFixed(6);

const updateRestaurantLocationSummary = (form, location = readRestaurantLocation(form)) => {
    const statusEl = form?.querySelector('[data-location-status]');
    if (!statusEl) {
        return;
    }
    statusEl.textContent = location
        ? 'Position OK'
        : 'Position requise';
    statusEl.dataset.coords = location
        ? `${formatCoordinate(location.lat)}, ${formatCoordinate(location.lng)}`
        : '';
};

const setRestaurantLocation = (form, location) => {
    const { lat, lng } = getRestaurantLocationInputs(form);
    if (lat) lat.value = location ? formatCoordinate(location.lat) : '';
    if (lng) lng.value = location ? formatCoordinate(location.lng) : '';
    updateRestaurantLocationSummary(form, location);
};

const updateMapCoordinatesDisplay = (location) => {
    const coordsEl = document.getElementById('restaurantLocationCoords');
    const confirmBtn = document.getElementById('confirmRestaurantMapBtn');
    if (coordsEl) {
        coordsEl.textContent = location
            ? `${formatCoordinate(location.lat)}, ${formatCoordinate(location.lng)}`
            : 'Aucune position choisie';
    }
    if (confirmBtn) {
        confirmBtn.disabled = !location;
    }
};

const ensureRestaurantMapMarker = (location) => {
    if (!restaurantLocationState.map || !window.L) {
        return;
    }
    if (!location) {
        if (restaurantLocationState.marker) {
            restaurantLocationState.map.removeLayer(restaurantLocationState.marker);
            restaurantLocationState.marker = null;
        }
        return;
    }
    if (!restaurantLocationState.marker) {
        restaurantLocationState.marker = window.L.marker([location.lat, location.lng]).addTo(restaurantLocationState.map);
    } else {
        restaurantLocationState.marker.setLatLng([location.lat, location.lng]);
    }
};

const formatErrors = (errors) => {
    if (!Array.isArray(errors)) {
        return '';
    }
    return errors
        .map((err) => {
            if (!err) return '';
            const field = err.field || err.path || err.param;
            const message = err.message || err.msg || err.error || '';
            return field ? `${field}: ${message}` : message;
        })
        .filter(Boolean)
        .join('\n');
};

const submitRegistration = async (form, payload) => {
    setFormMessage(form, '');
    setFormLoading(form, true);

    try {
        const response = await fetch(REGISTER_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json().catch(() => ({}));

        if (!response.ok) {
            const errorDetails = formatErrors(data.errors);
            const errorMessage = errorDetails || data.message || 'Une erreur est survenue.';
            setFormMessage(form, errorMessage, 'error');
            return;
        }

        setFormMessage(form, 'Inscription envoyée avec succès. Notre équipe vous contactera rapidement.', 'success');
        triggerCongrats(payload.type === 'driver' ? 'Bienvenue !' : 'Merci !');
        form.reset();
        if (payload.type === 'restaurant') {
            setRestaurantLocation(form, null);
        }
    } catch (error) {
        setFormMessage(form, 'Impossible de contacter le serveur. Réessayez dans quelques minutes.', 'error');
    } finally {
        setFormLoading(form, false);
    }
};

document.querySelectorAll('.registration-form[data-role]').forEach((form) => {
    form.addEventListener('submit', (event) => {
        event.preventDefault();

        const role = form.dataset.role;
        const payload = role === 'driver' ? buildDriverPayload(form) : buildRestaurantPayload(form);

        if (role === 'driver') {
            if (!payload.first_name || !payload.last_name || !payload.email || !payload.password || !payload.phone) {
                setFormMessage(form, 'Veuillez remplir tous les champs obligatoires.', 'error');
                return;
            }
        }

        if (role === 'restaurant') {
            if (!payload.name || !payload.email || !payload.password || !payload.lat || !payload.lng) {
                setFormMessage(form, 'Veuillez remplir tous les champs obligatoires.', 'error');
                return;
            }
            if (!payload.categories || payload.categories.length === 0) {
                setFormMessage(form, 'Choisissez au moins une catégorie.', 'error');
                return;
            }
        }

        submitRegistration(form, payload);
    });
});

const fetchCategories = async () => {
    const endpoints = ['/api/home-category', '/home-category'];
    for (const endpoint of endpoints) {
        try {
            const response = await fetch(endpoint);
            if (response.ok) {
                const data = await response.json();
                if (data && Array.isArray(data.data)) {
                    return data.data;
                }
            }
        } catch (error) {
            // continue to next endpoint
        }
    }
    return [];
};

const renderCategoryOptions = (categories) => {
    const containers = document.querySelectorAll('[data-category-options]');
    if (!containers.length) {
        return;
    }
    containers.forEach((container) => {
        container.innerHTML = '';
        categories.forEach((category) => {
            const label = document.createElement('label');
            label.className = 'category-option';

            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.value = category.slug;
            checkbox.name = 'categories[]';

            const image = document.createElement('img');
            image.src = resolveCategoryImageUrl(category);
            image.alt = category.name;
            image.className = 'category-option-image';
            image.width = 36;
            image.height = 36;
            image.loading = 'lazy';
            image.decoding = 'async';
            image.addEventListener('error', () => {
                if (image.src !== DEFAULT_CATEGORY_IMAGE) {
                    image.src = DEFAULT_CATEGORY_IMAGE;
                }
            });

            const text = document.createElement('span');
            text.textContent = category.name;
            text.className = 'category-option-label';

            label.appendChild(checkbox);
            label.appendChild(image);
            label.appendChild(text);
            container.appendChild(label);
        });
    });
};

fetchCategories().then((categories) => {
    if (Array.isArray(categories) && categories.length) {
        renderCategoryOptions(categories);
    }
});

const fetchWilayas = async () => {
    const endpoints = ['/api/geo/wilayas', '/geo/wilayas'];
    for (const endpoint of endpoints) {
        try {
            const response = await fetch(endpoint);
            if (response.ok) {
                const data = await response.json();
                if (data && Array.isArray(data.data)) {
                    return data.data;
                }
            }
        } catch (error) {
            // continue to next endpoint
        }
    }
    return [];
};

const fetchCommunes = async (wilayaCode) => {
    if (!wilayaCode) {
        return [];
    }
    const encoded = encodeURIComponent(wilayaCode);
    const endpoints = [
        `/api/geo/communes?wilaya_code=${encoded}`,
        `/geo/communes?wilaya_code=${encoded}`
    ];
    for (const endpoint of endpoints) {
        try {
            const response = await fetch(endpoint);
            if (response.ok) {
                const data = await response.json();
                if (data && Array.isArray(data.data)) {
                    return data.data;
                }
            }
        } catch (error) {
            // continue to next endpoint
        }
    }
    return [];
};

const initGeoSelectors = async () => {
    const form = document.querySelector('.restaurant-registration');
    if (!form) return;

    const wilayaSelect = form.querySelector('select[name="wilaya_code"]');
    const communeSelect = form.querySelector('select[name="commune_select"]');
    const communeInput = form.querySelector('input[name="commune_id"]');

    if (!wilayaSelect || !communeSelect || !communeInput) return;

    const wilayas = await fetchWilayas();
    if (!wilayas.length) {
        wilayaSelect.innerHTML = '<option value="">Wilayas indisponibles</option>';
        wilayaSelect.disabled = true;
        return;
    }

    wilayaSelect.innerHTML = '<option value="">Sélectionnez une wilaya</option>';
    wilayas.forEach((wilaya) => {
        const option = document.createElement('option');
        option.value = wilaya.code;
        option.textContent = wilaya.name_ar
            ? `${wilaya.code} - ${wilaya.name} (${wilaya.name_ar})`
            : `${wilaya.code} - ${wilaya.name}`;
        wilayaSelect.appendChild(option);
    });

    wilayaSelect.addEventListener('change', async () => {
        const code = wilayaSelect.value;
        communeInput.value = '';
        communeSelect.innerHTML = '<option value="">Sélectionnez une commune</option>';
        communeSelect.disabled = !code;
        if (!code) return;

        const communes = await fetchCommunes(code);
        if (!communes.length) {
            communeSelect.innerHTML = '<option value="">Aucune commune trouvée</option>';
            return;
        }

        communeSelect.innerHTML = '<option value="">Sélectionnez une commune</option>';
        communes.forEach((commune) => {
            const option = document.createElement('option');
            option.value = commune.id;
            option.textContent = commune.name_ar
                ? `${commune.name} (${commune.name_ar})`
                : commune.name;
            communeSelect.appendChild(option);
        });
    });

    communeSelect.addEventListener('change', () => {
        communeInput.value = communeSelect.value || '';
    });
};

const initRestaurantLocationPicker = () => {
    const form = document.querySelector('.restaurant-registration');
    const modal = document.getElementById('restaurantLocationModal');
    const openCard = form ? form.querySelector('[data-map-trigger]') : null;
    const openTrigger = openCard;
    const confirmBtn = document.getElementById('confirmRestaurantMapBtn');
    const mapContainer = document.getElementById('restaurantLocationMap');
    const closeTriggers = modal ? Array.from(modal.querySelectorAll('[data-map-close]')) : [];
    const defaultCenter = [36.7538, 3.0588];

    if (!form || !modal || !confirmBtn || !mapContainer || !openTrigger) {
        return;
    }

    const closeModal = () => {
        modal.classList.remove('is-open');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
    };

    const openModal = async () => {
        try {
            await loadLeafletAssets();
        } catch (error) {
            setFormMessage(form, 'La carte est indisponible pour le moment. Réessayez dans quelques instants.', 'error');
            return;
        }
        if (!window.L) {
            setFormMessage(form, 'La carte est indisponible pour le moment. Réessayez dans quelques instants.', 'error');
            return;
        }

        if (!restaurantLocationState.map) {
            restaurantLocationState.map = window.L.map(mapContainer, {
                zoomControl: true,
                scrollWheelZoom: true
            }).setView(defaultCenter, 6);

            window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap'
            }).addTo(restaurantLocationState.map);

            restaurantLocationState.map.on('click', (event) => {
                restaurantLocationState.pendingLocation = {
                    lat: event.latlng.lat,
                    lng: event.latlng.lng
                };
                ensureRestaurantMapMarker(restaurantLocationState.pendingLocation);
                updateMapCoordinatesDisplay(restaurantLocationState.pendingLocation);
            });
        }

        const existingLocation = readRestaurantLocation(form);
        restaurantLocationState.pendingLocation = existingLocation;
        ensureRestaurantMapMarker(existingLocation);
        updateMapCoordinatesDisplay(existingLocation);

        if (existingLocation) {
            restaurantLocationState.map.setView([existingLocation.lat, existingLocation.lng], 15);
        } else {
            restaurantLocationState.map.setView(defaultCenter, 6);
        }

        modal.classList.add('is-open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');

        window.setTimeout(() => {
            restaurantLocationState.map.invalidateSize();
        }, 80);
    };

    openTrigger.addEventListener('click', () => {
        void openModal();
    });
    openTrigger.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            void openModal();
        }
    });

    closeTriggers.forEach((trigger) => {
        trigger.addEventListener('click', closeModal);
    });

    confirmBtn.addEventListener('click', () => {
        if (!restaurantLocationState.pendingLocation) {
            return;
        }
        setRestaurantLocation(form, restaurantLocationState.pendingLocation);
        closeModal();
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && modal.classList.contains('is-open')) {
            closeModal();
        }
    });

    updateRestaurantLocationSummary(form);
};

initRestaurantLocationPicker();
initGeoSelectors();

const newsletterForm = document.querySelector(".newsletter-form");
if (newsletterForm) {
    newsletterForm.addEventListener("submit", async (event) => {
        event.preventDefault();

        const emailInput = newsletterForm.querySelector('input[name="email"]');
        const messageEl = newsletterForm.querySelector(".newsletter-message");
        const email = emailInput?.value?.trim() || "";

        if (!email) {
            if (messageEl) {
                messageEl.textContent = "Veuillez saisir une adresse email valide.";
                messageEl.className = "newsletter-message error";
            }
            return;
        }

        const payload = {
            email,
            source: "landing",
            locale: document.documentElement.lang || "fr"
        };

        const endpoints = ["/api/newsletter/subscribe", "/newsletter/subscribe"];
        let success = false;
        let lastError = null;

        for (const endpoint of endpoints) {
            try {
                const response = await fetch(endpoint, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload)
                });

                const data = await response.json().catch(() => ({}));
                if (response.ok) {
                    success = true;
                    if (messageEl) {
                        messageEl.textContent = "Merci ! Vous êtes bien inscrit.";
                        messageEl.className = "newsletter-message success";
                    }
                    triggerCongrats('Merci !');
                    newsletterForm.reset();
                    break;
                }

                lastError = data?.message || "Une erreur est survenue.";
            } catch (err) {
                lastError = "Impossible de contacter le serveur.";
            }
        }

if (!success && messageEl) {
    messageEl.textContent = lastError || "Une erreur est survenue.";
    messageEl.className = "newsletter-message error";
}
    });
}

const triggerCongrats = (title) => {
    const overlay = document.getElementById('congratsOverlay');
    if (!overlay) return;

    const titleEl = overlay.querySelector('.congrats-title');
    if (titleEl && title) {
        titleEl.textContent = title;
    }

    const blobsContainer = overlay.querySelector('.congrats-blobs');
    if (!blobsContainer) return;

    if (!blobsContainer.childElementCount) {
        for (let i = 0; i < 22; i += 1) {
            const blob = document.createElement('span');
            blob.className = 'congrats-blob';
            blobsContainer.appendChild(blob);
        }
    }

    overlay.classList.add('show');

    const blobs = Array.from(blobsContainer.children);
    blobs.forEach((blob) => {
        const angle = Math.random() * Math.PI * 2;
        const distance = 120 + Math.random() * 160;
        const x = Math.cos(angle) * distance;
        const y = Math.sin(angle) * distance;
        const duration = 700 + Math.random() * 600;
        const delay = Math.random() * 120;

        blob.animate(
            [
                { transform: 'translate(-50%, -50%) scale(0.6)', opacity: 0 },
                { transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px)) scale(1.1)`, opacity: 1 },
                { transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px)) scale(0.8)`, opacity: 0 }
            ],
            { duration, easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)', delay }
        );
    });

    window.setTimeout(() => {
        overlay.classList.remove('show');
    }, 1800);
};

// Add to cart functionality (demo)
document.querySelectorAll('.btn-add').forEach(btn => {
    btn.addEventListener('click', () => {
        const originalText = btn.textContent;
        btn.textContent = '✓ Ajouté';
        btn.style.background = '#16A34A';
        btn.style.transform = 'scale(0.95)';
        
        // Add cart animation
        const cartNotification = document.createElement('div');
        cartNotification.textContent = '+1';
        cartNotification.style.cssText = `
            position: fixed;
            top: 80px;
            right: 20px;
            background: var(--primary);
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
            z-index: 10000;
            animation: slideDown 0.3s ease-out;
            font-weight: 600;
        `;
        document.body.appendChild(cartNotification);
        
        setTimeout(() => {
            cartNotification.style.animation = 'slideUp 0.3s ease-out';
            setTimeout(() => cartNotification.remove(), 300);
        }, 2000);
        
        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.background = '';
            btn.style.transform = '';
        }, 2000);
    });
});

// Header scroll effect - optimized with requestAnimationFrame
let lastScroll = 0;
let headerTicking = false;
const header = document.querySelector('.header');

window.addEventListener('scroll', () => {
    if (!headerTicking) {
        window.requestAnimationFrame(() => {
            const currentScroll = window.pageYOffset;
            
            if (currentScroll > 100) {
                header.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.1)';
                header.style.transition = 'box-shadow 0.3s ease';
            } else {
                header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
            }
            
            lastScroll = currentScroll;
            headerTicking = false;
        });
        headerTicking = true;
    }
});

// Add CSS for fade-in animation and additional styles
const style = document.createElement('style');
style.textContent = `
    .category-card,
    .dish-card,
    .step-card {
        opacity: 0;
        transform: translateY(30px);
        transition: opacity 0.8s cubic-bezier(0.4, 0, 0.2, 1), 
                    transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
        will-change: opacity, transform;
    }
    
    .fade-in {
        opacity: 1 !important;
        transform: translateY(0) !important;
    }
    
    /* Prevent layout shift during scroll */
    .category-card,
    .dish-card,
    .step-card {
        backface-visibility: hidden;
        perspective: 1000px;
    }
    
    @keyframes slideDown {
        from {
            transform: translateY(-100%);
            opacity: 0;
        }
        to {
            transform: translateY(0);
            opacity: 1;
        }
    }
    
    @keyframes slideUp {
        from {
            transform: translateY(0);
            opacity: 1;
        }
        to {
            transform: translateY(-100%);
            opacity: 0;
        }
    }
    
    .dish-image::after {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.1) 100%);
        pointer-events: none;
    }
    
    .dish-image {
        position: relative;
    }
    
    .dish-image::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.15) 0%, transparent 50%);
        opacity: 0;
        transition: opacity 0.3s ease;
        pointer-events: none;
        z-index: 1;
    }
    
    .dish-card:hover .dish-image::before {
        opacity: 1;
    }
    
    .category-card {
        transition: all 0.3s ease;
    }
    
    .category-card:hover .category-icon {
        transform: scale(1.1) rotate(2deg);
    }
    
    .dish-image::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.15) 0%, transparent 50%);
        opacity: 0;
        transition: opacity 0.3s ease;
        pointer-events: none;
        z-index: 1;
    }
    
    .dish-card:hover .dish-image::before {
        opacity: 1;
    }
    
    @media (max-width: 968px) {
        .mobile-menu-toggle.active span:nth-child(1) {
            transform: rotate(45deg) translate(5px, 5px);
        }
        
        .mobile-menu-toggle.active span:nth-child(2) {
            opacity: 0;
        }
        
        .mobile-menu-toggle.active span:nth-child(3) {
            transform: rotate(-45deg) translate(7px, -6px);
        }
    }
`;
document.head.appendChild(style);



// Add image loading error handling
document.querySelectorAll('img').forEach(img => {
    img.addEventListener('error', function() {
        this.style.display = 'none';
        const fallback = document.createElement('div');
        fallback.style.cssText = `
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #F0FDF4 0%, #DCFCE7 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
        `;
        fallback.textContent = '🍽️';
        this.parentNode.appendChild(fallback);
    });
});
