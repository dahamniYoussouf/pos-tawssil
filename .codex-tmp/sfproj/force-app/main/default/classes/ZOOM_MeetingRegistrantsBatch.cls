public class ZOOM_MeetingRegistrantsBatch implements Database.Batchable<ZOOM_Utils.meetingInfoWrapper>, Database.Stateful, Database.AllowsCallouts {
    public list<ZOOM_Utils.meetingInfoWrapper> meetingInfo;
    map<String, ZOOM_Utils.registrantWrapper> users = new map<String, ZOOM_Utils.registrantWrapper>();
    public String accessToken;
    public String refreshToken;
    public ZOOM_MeetingRegistrantsBatch(String accessToken, String refreshToken, list<ZOOM_Utils.meetingInfoWrapper> records) {
        this.meetingInfo = records;
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }
    
    public Iterable<ZOOM_Utils.meetingInfoWrapper> start(Database.BatchableContext context) {
        return meetingInfo == null ? new List<ZOOM_Utils.meetingInfoWrapper>() : meetingInfo;
    }
    
    public void execute(Database.BatchableContext context, list<ZOOM_Utils.meetingInfoWrapper> meetingInfo) {
    
    // ⭐⭐⭐ AJOUTEZ CES VÉRIFICATIONS AU DÉBUT ⭐⭐⭐
    if (String.isBlank(accessToken)) {
        System.debug('Access token is null or empty, skipping registrant batch execution');
        return;
    }
    
    if (meetingInfo == null || meetingInfo.isEmpty()) {
        System.debug('No meetings to process registrants in execute method');
        return;
    }
    // ⭐⭐⭐ FIN DES VÉRIFICATIONS ⭐⭐⭐
    
    ZOOM_Utils util = new ZOOM_Utils();        
    for(ZOOM_Utils.meetingInfoWrapper meetingInfoElt : meetingInfo){
        
        // ⭐⭐⭐ VÉRIFICATION POUR CHAQUE MEETING ⭐⭐⭐
        if (meetingInfoElt == null) {
            System.debug('Meeting is null, skipping');
            continue;
        }
        
        if (String.isBlank(meetingInfoElt.id)) {
            System.debug('Meeting ID is blank for: ' + meetingInfoElt);
            continue;
        }
        // ⭐⭐⭐ FIN DES VÉRIFICATIONS ⭐⭐⭐
        
        system.debug('+++++++++++++++ Meeting meetingInfoElt' + meetingInfoElt);
        if(meetingInfoElt.occurrences != null){
            for(ZOOM_Utils.mettingInfoOccurence occranceElt : meetingInfoElt.occurrences){
                system.debug('Call With Occurance Batch '+meetingInfoElt.id+' - '+ occranceElt.occurrence_id);
                util.getRegistrantByMeeting(this.accessToken, meetingInfoElt, occranceElt, users);
            }
        }else{
            system.debug('Call Without Occurance Batch '+meetingInfoElt.id);
            util.getRegistrantByMeeting(this.accessToken, meetingInfoElt, null, users);
        }
    }
    system.debug(users.keySet());
}
    
    public void finish(Database.BatchableContext context) {
        Map<String, ZOOM_Utils.registrantWrapper> normalizedUsers = buildNormalizedUsers(users);
        system.debug('users users 22 '+JSON.serializePretty(normalizedUsers));

        if (normalizedUsers.isEmpty()) {
            System.debug('No registrants collected, skipping finish processing');
            return;
        }
        
        list<Lead> leads = [
            Select id, email, Webinar_Date__c, Webinar_ID__c, Webinar_Name__c, Ecosystem_Contribution__c,
                   joining_reason__c, Language__c, source__c, Job_Level__c, Organization_Size__c,
                   AI_Readiness__c, zoom_comments__c, Company, Phone, Industry, Title
            from lead where email IN : normalizedUsers.keySet()];
        list<Contact> Contacts = [Select id, email, Webinar_Date__c, Webinar_ID__c, Webinar_Name__c from contact where email IN : normalizedUsers.keySet()];
        system.debug('leads '+leads);
        ZOOM_Utils.registrantWrapper tmpEltUser;
        set<String> existingEmailsLead    = new set<String>();
        set<String> existingEmailsContact = new set<String>();
        list<lead>    toUpdateLead    = new list<lead>();
        list<Contact> toUpdateContact = new list<Contact>();
        
        for(Lead l : leads){
            system.debug('leads one  '+l);
            existingEmailsLead.add(normalizeEmail(l.Email));
            tmpEltUser = normalizedUsers.get(normalizeEmail(l.Email));
            if(!isRegistrantUsable(tmpEltUser))
                continue;
            system.debug('leads two  '+l);
            system.debug('here is '+tmpEltUser+'-'+l.email);
            if(l.Webinar_Date__c == null ||
               (l.Webinar_Date__c != null && l.Webinar_Date__c >= system.today() && tmpEltUser.startDate >= system.today() && tmpEltUser.startDate < l.Webinar_Date__c) ||
               (l.Webinar_Date__c != null && l.Webinar_Date__c < system.today() && tmpEltUser.startDate > l.Webinar_Date__c)){
                system.debug('leads 3 '+l);
                l.Webinar_Date__c           = tmpEltUser.startDate;
                l.Webinar_Date_time__c      = tmpEltUser.startDatetime;
                l.Webinar_ID__c             = tmpEltUser.meetinfInfo.id;
                l.Webinar_Name__c           = tmpEltUser.meetinfInfo.topic;
                l.Webinar_Registration_Date__c = tmpEltUser.userElt.create_time;
				l.Webinar_URL__c = tmpEltUser.userElt.join_url != null ? tmpEltUser.userElt.join_url.substringBefore('?') : null;

               
if(tmpEltUser.userElt.custom_questions != null){
    for(ZOOM_Utils.questions Cquestion : tmpEltUser.userElt.custom_questions){
        if (Cquestion == null || String.isBlank(Cquestion.title)) {
            continue;
        }
        String titleLower = Cquestion.title.toLowerCase().trim();
 
        if(titleLower == 'ecosystem_contribution__c' || containsIgnoreCase(Cquestion.title, 'ecosystem') || containsIgnoreCase(Cquestion.title, 'contribution') || containsIgnoreCase(Cquestion.title, 'system')){
            l.Ecosystem_Contribution__c = ZOOM_FieldTranslator.translateEcosystemContribution(Cquestion.value);
        }
        if(titleLower == 'joining_reason__c' || containsIgnoreCase(Cquestion.title, 'raison') || containsIgnoreCase(Cquestion.title, 'reason')){
            l.joining_reason__c = Cquestion.value;
        }
        if(titleLower == 'language__c' || containsIgnoreCase(Cquestion.title, 'language') || containsIgnoreCase(Cquestion.title, 'langue')){
    l.Language__c = ZOOM_FieldTranslator.translateLanguage(Cquestion.value);
        }
        if(titleLower == 'source__c' || containsIgnoreCase(Cquestion.title, 'hear') || containsIgnoreCase(Cquestion.title, 'entendu')){
            l.source__c = Cquestion.value;
        }
        if(titleLower == 'job_level__c' || containsIgnoreCase(Cquestion.title, 'category') || containsIgnoreCase(Cquestion.title, 'catégorie')){
            l.Job_Level__c = ZOOM_FieldTranslator.translateJobLevel(Cquestion.value);
        }
        if(titleLower == 'organization_size__c' || containsIgnoreCase(Cquestion.title, 'organization size') || containsIgnoreCase(Cquestion.title, 'taille') || containsIgnoreCase(Cquestion.title, 'size')){
            l.Organization_Size__c = ZOOM_FieldTranslator.translateOrganizationSize(Cquestion.value);
        }
        if(titleLower == 'ai_readiness__c' || containsIgnoreCase(Cquestion.title, 'ai readiness') || containsIgnoreCase(Cquestion.title, 'maturité ia') || containsIgnoreCase(Cquestion.title, 'artificial intelligence') || containsIgnoreCase(Cquestion.title, 'intelligence artificielle')){
            l.AI_Readiness__c = ZOOM_FieldTranslator.translateAIReadiness(Cquestion.value);
        }
        if(titleLower == 'industry' || containsIgnoreCase(Cquestion.title, 'industry') || containsIgnoreCase(Cquestion.title, 'secteur')){
            l.Industry = ZOOM_FieldTranslator.translateIndustry(Cquestion.value);
        }
    }
}
                l.zoom_comments__c = tmpEltUser.userElt.comments;
                if(String.isNotBlank(tmpEltUser.userElt.org)){
                    l.Company = tmpEltUser.userElt.org;
                }
                l.Phone    = tmpEltUser.userElt.phone;
                l.Industry = ZOOM_FieldTranslator.translateIndustry(l.Industry); // re-normalise si Industry vient du champ natif
                l.Title    = tmpEltUser.userElt.job_title;

                toUpdateLead.add(l);
            }
        }
        if (!toUpdateLead.isEmpty()) {
            logSaveResults(Database.update(toUpdateLead, false), 'Lead update');
        }

        for(Contact c : Contacts){
            existingEmailsContact.add(normalizeEmail(c.Email));
            tmpEltUser = normalizedUsers.get(normalizeEmail(c.Email));
            if(!isRegistrantUsable(tmpEltUser))
                continue;
            system.debug(tmpEltUser+'-'+c.email);
            if(c.Webinar_Date__c == null ||
               (c.Webinar_Date__c != null && c.Webinar_Date__c >= system.today() &&
                tmpEltUser.startDate >= system.today() &&
                tmpEltUser.startDate < c.Webinar_Date__c) ||
               (c.Webinar_Date__c != null && c.Webinar_Date__c < system.today() &&
                tmpEltUser.startDate >= system.today())
              ){
                c.Webinar_Date__c              = tmpEltUser.startDate;
                c.Webinar_Date_time__c         = tmpEltUser.startDatetime;
                c.Webinar_ID__c                = tmpEltUser.meetinfInfo.id;
                c.Webinar_Name__c              = tmpEltUser.meetinfInfo.topic;
                c.Webinar_Registration_Date__c = tmpEltUser.userElt.create_time;
                c.Webinar_URL__c = tmpEltUser.userElt.join_url != null ? tmpEltUser.userElt.join_url.substringBefore('?') : null;
                toUpdateContact.add(c);
            }
        }
        if (!toUpdateContact.isEmpty()) {
            logSaveResults(Database.update(toUpdateContact, false), 'Contact update');
        }

        // ── Création des nouveaux Leads ────────────────────────────────────────
        list<lead>  newLead    = new list<lead>();
        list<group> zoomqueue  = new list<group>();
        string Ecosystem_Contribution;
        string joining_reason;
        string language;
        string comment;
        string source;
        string jobLevel;
        string organizationSize;
        string aiReadiness;
        string industryValue;
        


        zoomqueue = [select Id from Group where Type = 'Queue' and name = 'Zoom Queue'];
        Id zoomQueueId = zoomqueue.isEmpty() ? null : zoomqueue[0].Id;
        if (zoomQueueId == null) {
            System.debug('Zoom Queue not found, new leads will keep the default owner');
        }

        for(String emailKey : normalizedUsers.keySet()){
            if(!existingEmailsLead.contains(emailKey.toLowerCase()) && !existingEmailsContact.contains(emailKey.toLowerCase())){
                tmpEltUser = normalizedUsers.get(emailKey);
                if(!isRegistrantUsable(tmpEltUser)) {
                    continue;
                }
                system.debug('tmpEltUser'                        + tmpEltUser);
                system.debug('tmpEltUser.userElt username '      + tmpEltUser.userElt);
                system.debug('tmpEltUser.userElt.org '           + tmpEltUser.userElt.org);
                system.debug('tmpEltUser.userElt.custom_questions ' + tmpEltUser.userElt.custom_questions);

                // Reset des champs custom pour chaque registrant
                Ecosystem_Contribution = null;
                joining_reason         = null;
                language               = null;
                comment                = null;
                source                 = null;
                jobLevel               = null;
                organizationSize       = null;
                aiReadiness            = null;
                industryValue          = null;
                
if(tmpEltUser.userElt.custom_questions != null){
    for(ZOOM_Utils.questions Cquestion : tmpEltUser.userElt.custom_questions){
        if (Cquestion == null || String.isBlank(Cquestion.title)) {
            continue;
        }
        String titleLower = Cquestion.title.toLowerCase().trim();
 
        if(titleLower == 'ecosystem_contribution__c' || containsIgnoreCase(Cquestion.title, 'ecosystem') || containsIgnoreCase(Cquestion.title, 'contribution') || containsIgnoreCase(Cquestion.title, 'system')){
            Ecosystem_Contribution = ZOOM_FieldTranslator.translateEcosystemContribution(Cquestion.value);
        }
        if(titleLower == 'joining_reason__c' || containsIgnoreCase(Cquestion.title, 'raison') || containsIgnoreCase(Cquestion.title, 'reason')){
            joining_reason = Cquestion.value;
        }
        if(titleLower == 'language__c' || containsIgnoreCase(Cquestion.title, 'language') || containsIgnoreCase(Cquestion.title, 'langue')){
            language = ZOOM_FieldTranslator.translateLanguage(Cquestion.value);
        }
        if(titleLower == 'source__c' || containsIgnoreCase(Cquestion.title, 'hear') || containsIgnoreCase(Cquestion.title, 'entendu')){
            source = Cquestion.value;
        }
        if(titleLower == 'job_level__c' || containsIgnoreCase(Cquestion.title, 'category') || containsIgnoreCase(Cquestion.title, 'catégorie')){
            jobLevel = ZOOM_FieldTranslator.translateJobLevel(Cquestion.value);
        }
        if(titleLower == 'organization_size__c' || containsIgnoreCase(Cquestion.title, 'organization size') || containsIgnoreCase(Cquestion.title, 'taille') || containsIgnoreCase(Cquestion.title, 'size')){
            organizationSize = ZOOM_FieldTranslator.translateOrganizationSize(Cquestion.value);
        }
        if(titleLower == 'ai_readiness__c' || containsIgnoreCase(Cquestion.title, 'ai readiness') || containsIgnoreCase(Cquestion.title, 'maturité ia') || containsIgnoreCase(Cquestion.title, 'artificial intelligence') || containsIgnoreCase(Cquestion.title, 'intelligence artificielle')){
            aiReadiness = ZOOM_FieldTranslator.translateAIReadiness(Cquestion.value);
        }
        if(titleLower == 'industry' || containsIgnoreCase(Cquestion.title, 'industry') || containsIgnoreCase(Cquestion.title, 'secteur')){
            industryValue = ZOOM_FieldTranslator.translateIndustry(Cquestion.value);
            // N.B. : déclarez "String industry = null;" avec les autres variables en début de boucle
        }
    }
}

                // Fallback Industry : champ natif Zoom si non trouvé dans custom questions
                if(String.isBlank(industryValue) && String.isNotBlank(tmpEltUser.userElt.industry)){
                    industryValue = ZOOM_FieldTranslator.translateIndustry(tmpEltUser.userElt.industry);
                }

                if(String.isBlank(tmpEltUser.userElt.country) || tmpEltUser.userElt.country.toLowerCase() != 'ca'){
                    tmpEltUser.userElt.state = null;
                }
                String companyName = String.isBlank(tmpEltUser.userElt.org) ? 'Zoom' : tmpEltUser.userElt.org;

                Lead leadToInsert = new Lead(
                    FirstName                  = tmpEltUser.userElt.first_name,
                    LastName                   = tmpEltUser.userElt.last_name != null ? tmpEltUser.userElt.last_name : 'Empty',
                    Email                      = tmpEltUser.userElt.email,
                    Phone                      = tmpEltUser.userElt.phone,
                    Industry                   = industryValue,
                    Title                      = tmpEltUser.userElt.job_title,
                    CountryCode                = tmpEltUser.userElt.country,
                    StateCode                  = tmpEltUser.userElt.state,
                    From_Zoom__c               = true,
                    Webinar_Date__c            = tmpEltUser.startDate,
                    Webinar_Date_time__c       = tmpEltUser.startDatetime,
                    Ecosystem_Contribution__c  = Ecosystem_Contribution,
                    joining_reason__c          = joining_reason,
                    Language__c                = language,
                    zoom_comments__c           = tmpEltUser.userElt.comments,
                    source__c                  = source,
                    Job_Level__c               = jobLevel,
                    Organization_Size__c       = organizationSize,
                    AI_Readiness__c            = aiReadiness,
                    Webinar_ID__c              = tmpEltUser.meetinfInfo.id,
                    Webinar_Name__c            = tmpEltUser.meetinfInfo.topic,
                    Webinar_Registration_Date__c = tmpEltUser.userElt.create_time,
                    Webinar_URL__c             = tmpEltUser.userElt.join_url != null ? tmpEltUser.userElt.join_url.substringBefore('?') : null,
                    Company                    = companyName
                );

                if (zoomQueueId != null) {
                    leadToInsert.OwnerId = zoomQueueId;
                }

                newLead.add(leadToInsert);
            }
        }
        if (!newLead.isEmpty()) {
            logSaveResults(Database.insert(newLead, false), 'Lead insert');
        }
        
        // Vérification avant d'appeler le participant batch
        if (String.isBlank(accessToken)) {
            System.debug('Access token is blank, skipping participant batch');
            return;
        }

        if (meetingInfo != null && !meetingInfo.isEmpty()) {
            // Filtrer les meetings avec un ID valide
            List<ZOOM_Utils.meetingInfoWrapper> validMeetings = new List<ZOOM_Utils.meetingInfoWrapper>();
            for (ZOOM_Utils.meetingInfoWrapper meeting : meetingInfo) {
                if (meeting != null && String.isNotBlank(meeting.id)) {
                    validMeetings.add(meeting);
                }
            }
            
            if (!validMeetings.isEmpty()) {
                Database.executeBatch(new ZOOM_MeetingParticipantBatch(accessToken, refreshToken, validMeetings), 5);
            } else {
                System.debug('No valid meetings to process participants');
            }
        } else {
            System.debug('meetingInfo is null or empty, skipping participant batch');
        }
    }
    
    private static Map<String, ZOOM_Utils.registrantWrapper> buildNormalizedUsers(Map<String, ZOOM_Utils.registrantWrapper> sourceUsers) {
        Map<String, ZOOM_Utils.registrantWrapper> normalizedUsers = new Map<String, ZOOM_Utils.registrantWrapper>();

        if (sourceUsers == null) {
            return normalizedUsers;
        }

        for (String emailKey : sourceUsers.keySet()) {
            String normalizedEmail = normalizeEmail(emailKey);
            if (normalizedEmail != null && sourceUsers.get(emailKey) != null) {
                normalizedUsers.put(normalizedEmail, sourceUsers.get(emailKey));
            }
        }

        return normalizedUsers;
    }

    private static String normalizeEmail(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }

    private static Boolean containsIgnoreCase(String sourceValue, String fragment) {
        return !String.isBlank(sourceValue) && !String.isBlank(fragment) && sourceValue.toLowerCase().contains(fragment.toLowerCase());
    }

    private static Boolean isRegistrantUsable(ZOOM_Utils.registrantWrapper registrant) {
        return registrant != null && registrant.userElt != null && registrant.meetinfInfo != null;
    }

    private static void logSaveResults(Database.SaveResult[] results, String operationName) {
        if (results == null) {
            return;
        }

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                continue;
            }

            for (Database.Error err : results[i].getErrors()) {
                System.debug(operationName + ' failed at index ' + i + ': ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
        }
    }
}
