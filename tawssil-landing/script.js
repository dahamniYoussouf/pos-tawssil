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
const nav = document.querySelector('.nav');
const headerActions = document.querySelector('.header-actions');

if (mobileMenuToggle) {
    mobileMenuToggle.addEventListener('click', () => {
        nav.classList.toggle('mobile-open');
        headerActions.classList.toggle('mobile-open');
        mobileMenuToggle.classList.toggle('active');
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
document.querySelectorAll('.category-card, .dish-card, .step-card, .stat-card, .app-showcase-card, .application-card, .faq-item').forEach(el => {
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

// FAQ Accordion functionality
document.querySelectorAll('.faq-item').forEach(item => {
    const question = item.querySelector('.faq-question');
    if (question) {
        question.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            // Close all other FAQ items
            document.querySelectorAll('.faq-item').forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                }
            });
            
            // Toggle current item
            if (isActive) {
                item.classList.remove('active');
            } else {
                item.classList.add('active');
            }
        });
    }
});

// Form submission with realistic validation
const registrationForm = document.querySelector('.registration-form');
if (registrationForm) {
    registrationForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        const formData = new FormData(registrationForm);
        const restaurantName = registrationForm.querySelector('input[type="text"]').value;
        const phone = registrationForm.querySelector('input[type="tel"]').value;
        const wilaya = registrationForm.querySelector('select').value;
        
        // Simple validation
        if (!restaurantName || !phone || !wilaya || wilaya === 'Sélectionnez votre wilaya') {
            alert('Veuillez remplir tous les champs.');
            return;
        }
        
        // Show success message
        const successMsg = document.createElement('div');
        successMsg.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: white;
            padding: 32px;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            z-index: 10000;
            text-align: center;
            max-width: 400px;
        `;
        successMsg.innerHTML = `
            <div style="font-size: 48px; margin-bottom: 16px;">✅</div>
            <h3 style="font-size: 20px; font-weight: 700; margin-bottom: 8px; color: var(--primary);">Demande envoyée !</h3>
            <p style="color: var(--text-secondary); margin-bottom: 24px;">Merci ${restaurantName}, nous vous contacterons bientôt.</p>
            <button onclick="this.parentElement.remove()" style="background: var(--primary); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">Fermer</button>
        `;
        document.body.appendChild(successMsg);
        
        registrationForm.reset();
    });
}

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

// Parallax effect for hero section - improved and smoother
let ticking = false;
window.addEventListener('scroll', () => {
    if (!ticking) {
        window.requestAnimationFrame(() => {
            const scrolled = window.pageYOffset;
            const heroImage = document.querySelector('.hero-image');
            if (heroImage && scrolled < window.innerHeight * 1.5) {
                // Reduced parallax intensity for smoother effect
                const parallaxValue = scrolled * 0.3;
                const opacityValue = Math.max(0.5, 1 - (scrolled / window.innerHeight) * 0.3);
                heroImage.style.transform = `translateY(${parallaxValue}px)`;
                heroImage.style.opacity = opacityValue;
            }
            ticking = false;
        });
        ticking = true;
    }
});

// Counter animation function (defined below with stats observer)

// Initialize counter animation when stats section is visible
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const statValues = entry.target.querySelectorAll('.stat-value[data-target]');
            statValues.forEach(stat => {
                const target = parseFloat(stat.getAttribute('data-target'));
                const unit = stat.nextElementSibling?.textContent || '';
                
                if (unit.includes('K+')) {
                    animateCounter(stat, target, 2000, (val) => Math.floor(val) + 'K+');
                } else if (unit.includes('+')) {
                    animateCounter(stat, target, 2000, (val) => Math.floor(val) + '+');
                } else if (unit.includes('/5')) {
                    animateCounter(stat, target, 2000, (val) => val.toFixed(1));
                } else {
                    animateCounter(stat, target, 2000, (val) => Math.floor(val));
                }
            });
            statsObserver.unobserve(entry.target);
        }
    });
}, { threshold: 0.5 });

const statsSection = document.querySelector('.statistics');
if (statsSection) {
    statsObserver.observe(statsSection);
}

// Updated counter animation function
const animateCounter = (element, target, duration = 2000, formatter = (val) => Math.floor(val)) => {
    let start = 0;
    const increment = target / (duration / 16);
    const timer = setInterval(() => {
        start += increment;
        if (start >= target) {
            element.textContent = formatter(target);
            clearInterval(timer);
        } else {
            element.textContent = formatter(start);
        }
    }, 16);
};

// Add CSS for fade-in animation and additional styles
const style = document.createElement('style');
style.textContent = `
    .category-card,
    .dish-card,
    .step-card,
    .stat-card,
    .application-card {
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
    .step-card,
    .stat-card,
    .application-card {
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
        .nav.mobile-open {
            display: flex;
            flex-direction: column;
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            padding: 24px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        
        .header-actions.mobile-open {
            display: flex;
            flex-direction: column;
            position: absolute;
            top: calc(100% + 200px);
            left: 0;
            right: 0;
            background: white;
            padding: 24px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        
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
