public class ZOOM_FieldTranslator {

    // ─────────────────────────────────────────────────────────────────────────
    // JOB LEVEL (Job_Level__c) - GARDE LES VALEURS ANGLAISES TELLES QUELLES
    // ─────────────────────────────────────────────────────────────────────────
    private static final Map<String, String> JOB_LEVEL_MAP = new Map<String, String>{
        // Valeurs françaises → Anglais (pour la traduction)
        'haute direction'               => 'Executive & VP',
        'direction ou gestion'          => 'Management',
        'professionnel'                 => 'Professional',
        'chercheur et universitaire'    => 'Research & Academic',
        'entrepreneur'                  => 'Entrepreneur',
        'étudiant'                      => 'Student',
        'autre'                         => 'Other',
        // Valeurs anglaises - retournent inchangées
        'executive & vp'                => 'Executive & VP',
        'management'                    => 'Management',
        'professional'                  => 'Professional',
        'research & academic'           => 'Research & Academic',
        'entrepreneur'                  => 'Entrepreneur',
        'student'                       => 'Student',
        'other'                         => 'Other'
    };

    public static String translateJobLevel(String raw) {
        return lookupMap(JOB_LEVEL_MAP, raw);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ORGANIZATION SIZE - GARDE LES VALEURS ANGLAISES TELLES QUELLES
    // ─────────────────────────────────────────────────────────────────────────
    private static final Map<String, String> ORG_SIZE_MAP = new Map<String, String>{
        // Valeurs françaises → Anglais
        'micro-entreprise : 1 à 10 employés'        => 'Micro enterprise: 1–10 employees',
        'petite entreprise : 11 à 99 employés'      => 'Small enterprise: 11–99 employees',
        'moyenne entreprise : 100 à 499 employés'   => 'Medium enterprise: 100–499 employees',
        'grande entreprise : 500 employés et plus'  => 'Large enterprise: 500+ employees',
        // Variantes sans accents
        'micro-entreprise : 1 a 10 employes'        => 'Micro enterprise: 1–10 employees',
        'petite entreprise : 11 a 99 employes'      => 'Small enterprise: 11–99 employees',
        'moyenne entreprise : 100 a 499 employes'   => 'Medium enterprise: 100–499 employees',
        'grande entreprise : 500 employes et plus'  => 'Large enterprise: 500+ employees',
        // Valeurs anglaises - retournent inchangées
        'micro enterprise: 1-10 employees'          => 'Micro enterprise: 1–10 employees',
        'micro enterprise: 1–10 employees'          => 'Micro enterprise: 1–10 employees',
        'small enterprise: 11-99 employees'         => 'Small enterprise: 11–99 employees',
        'small enterprise: 11–99 employees'         => 'Small enterprise: 11–99 employees',
        'medium enterprise: 100-499 employees'      => 'Medium enterprise: 100–499 employees',
        'medium enterprise: 100–499 employees'      => 'Medium enterprise: 100–499 employees',
        'large enterprise: 500+ employees'          => 'Large enterprise: 500+ employees'
    };

    public static String translateOrganizationSize(String raw) {
        return lookupMap(ORG_SIZE_MAP, raw);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INDUSTRY - GARDE LES VALEURS ANGLAISES TELLES QUELLES
    // ─────────────────────────────────────────────────────────────────────────
    private static final Map<String, String> INDUSTRY_MAP = new Map<String, String>{
        // Valeurs françaises → Anglais
        'agriculture, foresterie et mines'                  => 'Agriculture, Forestry & Mining',
        'alimentation et biens de consommation'             => 'Food & Consumer Goods',
        'commerce de détail'                                => 'Retail',
        'commerce de detail'                                => 'Retail',
        'construction et immobilier'                        => 'Construction & Real Estate',
        'fabrication et industrie manufacturière'           => 'Manufacturing & Industrial',
        'fabrication et industrie manufacturiere'           => 'Manufacturing & Industrial',
        'énergie, ressources et environnement'              => 'Energy, Resources & Environment',
        'energie, ressources et environnement'              => 'Energy, Resources & Environment',
        'transport, logistique et chaîne d\'approvisionnement' => 'Transportation, Logistics & Supply Chain',
        'technologies matérielles et semi-conducteurs'      => 'Hardware & Semiconductors',
        'logiciels, ia et technologies numériques'          => 'Software, AI & Digital Technologies',
        'logiciels, ia et technologies numeriques'          => 'Software, AI & Digital Technologies',
        'télécommunications'                                => 'Telecommunications',
        'telecommunications'                                => 'Telecommunications',
        'services financiers et assurances'                 => 'Financial Services & Insurance',
        'santé, sciences de la vie et biotechnologie'       => 'Healthcare, Life Sciences & Biotech',
        'éducation et recherche'                            => 'Education & Research',
        'education et recherche'                            => 'Education & Research',
        'médias, divertissement et culture'                 => 'Media, Entertainment & Culture',
        'medias, divertissement et culture'                 => 'Media, Entertainment & Culture',
        'gouvernement et secteur public'                    => 'Government & Public Sector',
        'organismes à but non lucratif'                     => 'Non-Profit & Social Impact',
        'organismes a but non lucratif'                     => 'Non-Profit & Social Impact',
        'services professionnels (conseil, juridique, rh, comptabilité)' => 'Professional Services (Consulting, Legal, HR, Accounting)',
        'tourisme, voyages et loisirs'                      => 'Travel, Tourism & Leisure',
        'autre'                                             => 'Other',
        // Valeurs anglaises - retournent inchangées
        'agriculture, forestry & mining'                    => 'Agriculture, Forestry & Mining',
        'food & consumer goods'                             => 'Food & Consumer Goods',
        'retail'                                            => 'Retail',
        'construction & real estate'                        => 'Construction & Real Estate',
        'manufacturing & industrial'                        => 'Manufacturing & Industrial',
        'energy, resources & environment'                   => 'Energy, Resources & Environment',
        'transportation, logistics & supply chain'          => 'Transportation, Logistics & Supply Chain',
        'hardware & semiconductors'                         => 'Hardware & Semiconductors',
        'software, ai & digital technologies'               => 'Software, AI & Digital Technologies',
        'telecommunications'                                => 'Telecommunications',
        'financial services & insurance'                    => 'Financial Services & Insurance',
        'healthcare, life sciences & biotech'               => 'Healthcare, Life Sciences & Biotech',
        'education & research'                              => 'Education & Research',
        'media, entertainment & culture'                    => 'Media, Entertainment & Culture',
        'government & public sector'                        => 'Government & Public Sector',
        'non-profit & social impact'                        => 'Non-Profit & Social Impact',
        'professional services (consulting, legal, hr, accounting)' => 'Professional Services (Consulting, Legal, HR, Accounting)',
        'travel, tourism & leisure'                         => 'Travel, Tourism & Leisure',
        'other'                                             => 'Other'
    };

    public static String translateIndustry(String raw) {
        return lookupMap(INDUSTRY_MAP, raw);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ECOSYSTEM CONTRIBUTION - GARDE LES VALEURS ANGLAISES TELLES QUELLES
    // ─────────────────────────────────────────────────────────────────────────
    private static final Map<String, String> ECOSYSTEM_MAP = new Map<String, String>{
        // Valeurs françaises → API Names
        'startup (entreprise technologique à fort potentiel de croissance)' => 'Enterprise - Supply chain user',
        'fournisseur de solutions en ia ou technologie' => 'Service Provider - Transport, logistics or supply chain',
        'adopteur de l\'ia' => 'Service Provider - AI or digital technologies',
        'investisseur - fonds d\'investissement' => 'Service Provider - Other professional services',
        'organisme public ou politique' => 'Academic - University, research center or other institution',
        'chercheur / universitaire' => 'Investor, Bank or VC',
        'organisation à but non lucratif, association ou incubateur' => 'Business incubator or accelerator',
        'délégation internationale' => 'Public sector or governmental organization',
        'autre' => 'Professional association or other non governmental organization',
        // Variantes sans accents
        'startup (entreprise technologique a fort potentiel de croissance)' => 'Enterprise - Supply chain user',
        'organisation a but non lucratif, association ou incubateur' => 'Business incubator or accelerator',
        'delegation internationale' => 'Public sector or governmental organization',
        // Valeurs anglaises - retournent inchangées
        'enterprise - supply chain user' => 'Enterprise - Supply chain user',
        'service provider - transport, logistics or supply chain' => 'Service Provider - Transport, logistics or supply chain',
        'service provider - ai or digital technologies' => 'Service Provider - AI or digital technologies',
        'service provider - other professional services' => 'Service Provider - Other professional services',
        'academic - university, research center or other institution' => 'Academic - University, research center or other institution',
        'investor, bank or vc' => 'Investor, Bank or VC',
        'business incubator or accelerator' => 'Business incubator or accelerator',
        'public sector or governmental organization' => 'Public sector or governmental organization',
        'professional association or other non governmental organization' => 'Professional association or other non governmental organization',
        // Valeurs Zoom anglaises directes
        'startup (high-growth tech business)' => 'Enterprise - Supply chain user',
        'ai or technology solution provider' => 'Service Provider - Transport, logistics or supply chain',
        'ai adopter' => 'Service Provider - AI or digital technologies',
        'investor - vc fund' => 'Service Provider - Other professional services',
        'public or political organization' => 'Academic - University, research center or other institution',
        'researcher / academic' => 'Investor, Bank or VC',
        'non-profit, association, or incubator' => 'Business incubator or accelerator',
        'international delegation' => 'Public sector or governmental organization',
        'other' => 'Professional association or other non governmental organization'
    };

    public static String translateEcosystemContribution(String raw) {
        return lookupMap(ECOSYSTEM_MAP, raw);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // AI READINESS - GARDE LES VALEURS ANGLAISES TELLES QUELLES
    // ─────────────────────────────────────────────────────────────────────────
    private static final Map<String, String> AI_READINESS_MAP = new Map<String, String>{
        // Valeurs françaises → API Names
        'pas encore utilisée' => 'High',
        'exploration d\'opportunités' => 'Medium',
        'projet pilote en cours' => 'Low',
        'solutions partiellement déployées' => 'None',
        'adoption stratégique' => 'Strategic AI adoption',
        'fournisseur ou entreprise centrée sur l\'ia' => 'AI is core to our business (AI product, service, or solution provider)',
        // Variantes sans accents
        'pas encore utilisee' => 'High',
        'exploration d\'opportunites' => 'Medium',
        'solutions partiellement deployees' => 'None',
        'adoption strategique' => 'Strategic AI adoption',
        'fournisseur ou entreprise centree sur l\'ia' => 'AI is core to our business (AI product, service, or solution provider)',
        // Valeurs anglaises - retournent inchangées
        'high' => 'High',
        'medium' => 'Medium',
        'low' => 'Low',
        'none' => 'None',
        'strategic ai adoption' => 'Strategic AI adoption',
        'not yet using ai' => 'High',
        'exploring opportunities' => 'Medium',
        'pilot project in progress' => 'Low',
        'partial deployment of ai solutions' => 'None',
        'ai is core to our business (ai product, service, or solution provider)' => 'AI is core to our business (AI product, service, or solution provider)'
    };

    public static String translateAIReadiness(String raw) {
        return lookupMap(AI_READINESS_MAP, raw);
    }

    
    
    // Ajoutez dans ZOOM_FieldTranslator
private static final Map<String, String> LANGUAGE_MAP = new Map<String, String>{
    'français' => 'French',
    'francais' => 'French',
    'anglais' => 'English',
    'english' => 'English'
};

public static String translateLanguage(String raw) {
    if (String.isBlank(raw)) return raw;
    String key = raw.toLowerCase().trim();
    String translated = LANGUAGE_MAP.get(key);
    return translated != null ? translated : raw;
}
    // ─────────────────────────────────────────────────────────────────────────
    // MÉTHODES GÉNÉRIQUES
    // ─────────────────────────────────────────────────────────────────────────
    public static String translate(String sfFieldName, String rawValue) {
        if (String.isBlank(sfFieldName) || String.isBlank(rawValue)) return rawValue;
        switch on sfFieldName.toLowerCase().trim() {
            when 'job_level__c' { return translateJobLevel(rawValue); }
            when 'organization_size__c' { return translateOrganizationSize(rawValue); }
            when 'industry' { return translateIndustry(rawValue); }
            when 'ecosystem_contribution__c' { return translateEcosystemContribution(rawValue); }
            when 'ai_readiness__c' { return translateAIReadiness(rawValue); }
            when else { return rawValue; }
        }
    }

    // Méthodes alias pour compatibilité avec les tests
    public static String translateOrgSize(String raw) {
        return translateOrganizationSize(raw);
    }

    public static String translateEcosystem(String raw) {
        return translateEcosystemContribution(raw);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UTILITAIRE
    // ─────────────────────────────────────────────────────────────────────────
    private static String lookupMap(Map<String, String> translationMap, String raw) {
        if (String.isBlank(raw)) return raw;
        String key = raw.toLowerCase().trim();
        String translated = translationMap.get(key);
        return translated != null ? translated : raw;
    }
}