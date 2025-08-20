/**
 * Created by Gunwoo Park
 */

public with sharing class TF_MuleSoftCaller {
     public static final String MULE_GW_URL = 'https://9ae5-119-192-206-86.ngrok-free.app/api/agent/events'; // MuleSoft API Gateway URL
     // https://9ae5-119-192-206-86.ngrok-free.app/api/agent/events
     public static final String TOKEN_URL = 'https://anypoint.mulesoft.com/accounts/oauth2/token';
     public static final String CLIENT_ID = 'YOUR_CLIENT_ID';
     public static final String CLIENT_SECRIT = 'YOUR_CLIENT_SECRET';
/*
    @InvocableMethod(label='MuleSoftServiceName'
                     description='For example: /getCustomer')
    public static List<String> callMuleSoftApi(List<String> endpointPath) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String accessToken = getAccessToken();
        System.debug('callMuleSoftApi:accessToken: ' + accessToken);
        request.setEndpoint(MULE_GW_URL + endpointPath);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        List<String> responses = new List<String>();

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                responses.add(response.getBody());
                System.debug('callMuleSoftApi:response: ' + responses);
                return responses;
            } else {
                responses.add('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
                System.debug('callMuleSoftApi:response: ' + responses);
                return responses;
            }
        } catch (Exception e) {
            responses.add('Exception: ' + e.getMessage());
            System.debug('callMuleSoftApi:Exception: ' + responses);
            return responses;
        }
    }
*/
   @InvocableMethod(label='MuleSoftServiceNameSimple'
                     description='Simple Call Out')
   public static List<String> callMuleSoftApiSimple(List<string> lstStr)  { 
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        List<String> results = new List<String>();
        String strBody = lstStr[0];

        Map<String, Object> requestBody = new Map<String, Object>{
            'body' => strBody
        };

        String jsonBody = JSON.serialize(requestBody);

        request.setEndpoint(MULE_GW_URL); // 호출할 URL
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        System.debug('jsonBody:' + jsonBody);
        request.setBody(jsonBody);

        try {
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                System.debug('Response: ' + response.getBody());
                results.add(response.getBody());
                return results;
            } else {
                System.debug('Response:Error Status: ' + response.getStatusCode());
                results.add(response.getStatusCode()+'');
                return results;
            }

        } catch (CalloutException e) {
            System.debug('Response:CalloutException: ' + e.getMessage());
            results.add(e.getMessage());
            return  results;
        }
   }

   public static String getAccessToken() {
        MuleSoftToken__c tokenSetting = MuleSoftToken__c.getInstance();
        DateTime now = DateTime.now();

        if (tokenSetting != null &&
                tokenSetting.AccessToken__c != null &&
                tokenSetting.ExpiresAt__c != null &&
                tokenSetting.ExpiresAt__c > now) {
            return tokenSetting.AccessToken__c;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(TOKEN_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'grant_type=client_credentials' +
                '&client_id=' + EncodingUtil.urlEncode(CLIENT_ID, 'UTF-8') +
                '&client_secret=' + EncodingUtil.urlEncode(CLIENT_SECRIT, 'UTF-8');

        request.setBody(body);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String accessToken = (String) result.get('access_token');
                Integer expiresIn = ((Integer) result.get('expires_in')); // 단위: 초
                DateTime expiresAt = now.addSeconds(expiresIn - 60); // 1분 여유

                if (tokenSetting == null) {
                    tokenSetting = new MuleSoftToken__c();
                }
                tokenSetting.AccessToken__c = accessToken;
                tokenSetting.ExpiresAt__c = expiresAt;
                upsert tokenSetting;
                return accessToken;
            } else {
                return 'Error: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }
}