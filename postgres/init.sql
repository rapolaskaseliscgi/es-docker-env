-- CREATE USER testuser LOGIN PASSWORD 'password';
CREATE DATABASE testdb WITH OWNER testuser;
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;

\connect testdb


create type public.securityclassification as enum ('PUBLIC', 'PRIVATE', 'RESTRICTED');

alter type public.securityclassification owner to testuser;


create table public.case_data
(
    id                       bigserial
        primary key,
    created_date             timestamp default now() not null,
    last_modified            timestamp,
    jurisdiction             varchar(255)            not null,
    case_type_id             varchar(255)            not null,
    state                    varchar(255)            not null,
    data                     jsonb                   not null,
    data_classification      jsonb,
    reference                bigint                  not null
        unique,
    security_classification  securityclassification  not null,
    version                  integer   default 1,
    last_state_modified_date timestamp,
    supplementary_data       jsonb,
    marked_by_logstash       boolean   default false,
    resolved_ttl             date,
    constraint case_pointer_always_marked_by_logstash
        check (marked_by_logstash OR (NOT ((data = '{}'::jsonb) AND ((state)::text = ''::text))))
);


INSERT INTO public.case_data (
    id,
    created_date,
    last_modified,
    jurisdiction,
    case_type_id,
    state,
    data,
    reference,
    security_classification,
    last_state_modified_date,
    supplementary_data
) VALUES (
    3396427,
    TIMESTAMP '2020-07-28 21:22:55.726',
    TIMESTAMP '2024-03-05 14:20:03.538',
    'SSCS',
    'Benefit',
    'appealCreated',
    $${
      "panel":{"assignedTo":null,"medicalMember":null,"disabilityQualifiedMember":null},
      "addedDocuments":null,
      "preWorkAllocation":"Yes",
      "jointPartyId":"e7bd7ffc-0336-4e2c-baef-a45bed2cae95",
      "workBasketHearingDate":null,
      "subscriptions":{
        "appellantSubscription":{},
        "supporterSubscription":{},
        "representativeSubscription":{},
        "appointeeSubscription":{},
        "jointPartySubscription":{}
      },
      "workBasketHearingEpimsId":null,
      "SearchCriteria":{
        "OtherCaseReferences":[{"id":"0c64355b-3939-4444-a7de-3a6b14c4d43c","value":"AB1234567Z"}],
        "SearchParties":[{"id":"a5dc10c1-a5bf-435b-be07-146b1fccd6c9","value":{"Name":"Mr Daniel Gleeballs","PostCode":"KT2 5BU","DateOfBirth":"2000-03-01","AddressLine1":"24 Test Street"}}]
      },
      "regionalProcessingCenter":{"phoneNumber":null,"faxNumber":null,"epimsId":null,"address1":null,"address2":null,"email":null,"address3":null,"hearingRoute":null,"postcode":null,"city":null,"name":null,"address4":null},
      "caseCreated":"2020-05-12",
      "appeal":{
        "hearingType":null,
        "rep":{"id":"a118051b-4a2f-4142-a164-13eab80003e3","identity":{},"address":{},"contact":{},"organisation":null,"hasRepresentative":null,"name":{}},
        "appellant":{
          "id":"b0d16281-751b-4deb-a554-5c6a117a6471",
          "identity":{"nino":"AB1234567Z","dob":"2000-03-01"},
          "contact":{"phone":"07123456789","mobile":null,"email":null},
          "organisation":null,
          "isAppointee":"No",
          "appointee":{"id":"7f4bef65-617d-469f-8211-54026690e762","identity":{"nino":null,"dob":null},"address":{},"contact":{"phone":null,"mobile":null,"email":null},"organisation":null,"name":{"lastName":null,"title":null,"firstName":null}},
          "isAddressSameAsAppointee":null,
          "address":{"town":"London","postcode":"KT2 5BU","line1":"24 Test Street"},
          "confidentialityRequired":null,
          "name":{"lastName":"Gleeballs","title":"Mr","firstName":"Daniel"},
          "role":{}
        },
        "signer":null,
        "receivedVia":"Online",
        "appealReasons":{"reasons":[]},
        "benefitType":{"description":null,"code":null},
        "mrnDetails":{"dwpIssuingOffice":"DWP","mrnDate":"2019-11-22","mrnMissingReason":null,"mrnLateReason":null},
        "hearingOptions":{},
        "hearingSubtype":{}
      },
      "sscsDocument":[
        {
          "id":"01f79fca-4f1a-4c11-9247-f9c0ac9c9a94",
          "value":{
            "documentComment":"3MB.pdf upload",
            "documentDateAdded":"2019-11-12",
            "documentLink":{
              "document_filename":"3MB.pdf",
              "document_binary_url":"http://dm-store-perftest.service.core-compute-perftest.internal:443/documents/847a9df3-e173-4638-a3e0-4d1d40e04153/binary",
              "document_url":"http://dm-store-perftest.service.core-compute-perftest.internal:443/documents/847a9df3-e173-4638-a3e0-4d1d40e04153"
            },
            "documentType":"Other evidence"
          }
        },
        {"id":"5095bd52-61c1-495b-94c0-410479b62663","value":{}}
      ]
    }$$::jsonb,
    1595971375787232,
    'PUBLIC'::securityclassification,
    TIMESTAMP '2020-07-28 21:22:55.726',
    NULL
);

INSERT INTO public.case_data (
    id,
    created_date,
    last_modified,
    jurisdiction,
    case_type_id,
    state,
    data,
    reference,
    security_classification,
    last_state_modified_date,
    supplementary_data
) VALUES (
    3416980,
    TIMESTAMP '2020-08-03 18:44:23.623',
    TIMESTAMP '2024-03-05 14:20:03.502',
    'SSCS',
    'Benefit',
    'appealCreated',
    $${
      "panel":{"assignedTo":null,"medicalMember":null,"disabilityQualifiedMember":null},
      "addedDocuments":null,
      "preWorkAllocation":"Yes",
      "jointPartyId":"d720435e-e9eb-4e1c-880c-1005002310a6",
      "workBasketHearingDate":null,
      "subscriptions":{
        "appellantSubscription":{},
        "supporterSubscription":{},
        "representativeSubscription":{},
        "appointeeSubscription":{},
        "jointPartySubscription":{}
      },
      "workBasketHearingEpimsId":null,
      "SearchCriteria":{
        "OtherCaseReferences":[{"id":"2000d2a1-24ab-4e79-8f80-83caf5158b34","value":"AB1234567Z"}],
        "SearchParties":[{"id":"93a2d7d9-3390-4991-b967-811727a77cd1","value":{"Name":"Mr Daniel Gleeballs","PostCode":"KT2 5BU","DateOfBirth":"2000-03-01","AddressLine1":"24 Test Street"}}]
      },
      "regionalProcessingCenter":{"phoneNumber":null,"faxNumber":null,"epimsId":null,"address1":null,"address2":null,"email":null,"address3":null,"hearingRoute":null,"postcode":null,"city":null,"name":null,"address4":null},
      "caseCreated":"2020-05-12",
      "appeal":{
        "hearingType":null,
        "rep":{"id":"e4e8e5d2-573d-4aeb-bc8f-5e0ec2a9d84c","identity":{},"address":{},"contact":{},"organisation":null,"hasRepresentative":null,"name":{}},
        "appellant":{
          "id":"33be8a80-0bb0-406e-bb01-8a29fbda36e5",
          "identity":{"nino":"AB1234567Z","dob":"2000-03-01"},
          "contact":{"phone":"07123456789","mobile":null,"email":null},
          "organisation":null,
          "isAppointee":"No",
          "appointee":{"id":"4e1b3a79-cf58-4320-bca3-2921003e96ba","identity":{"nino":null,"dob":null},"address":{},"contact":{"phone":null,"mobile":null,"email":null},"organisation":null,"name":{"lastName":null,"title":null,"firstName":null}},
          "isAddressSameAsAppointee":null,
          "address":{"town":"London","postcode":"KT2 5BU","line1":"24 Test Street"},
          "confidentialityRequired":null,
          "name":{"lastName":"Gleeballs","title":"Mr","firstName":"Daniel"},
          "role":{}
        },
        "signer":null,
        "receivedVia":"Online",
        "appealReasons":{"reasons":[]},
        "benefitType":{"description":null,"code":null},
        "mrnDetails":{"dwpIssuingOffice":"DWP","mrnDate":"2019-11-22","mrnMissingReason":null,"mrnLateReason":null},
        "hearingOptions":{},
        "hearingSubtype":{}
      },
      "sscsDocument":[
        {
          "id":"31a54b68-3a0b-447f-87f1-c9f5d57f70cb",
          "value":{
            "documentComment":"3MB.pdf upload",
            "documentDateAdded":"2019-11-12",
            "documentLink":{
              "document_filename":"3MB.pdf",
              "document_binary_url":"http://dm-store-perftest.service.core-compute-perftest.internal:443/documents/24fbd416-7e61-4c31-af79-d8ee2961eb42/binary",
              "document_url":"http://dm-store-perftest.service.core-compute-perftest.internal:443/documents/24fbd416-7e61-4c31-af79-d8ee2961eb42"
            },
            "documentType":"Other evidence"
          }
        },
        {"id":"bf172aff-4c7d-42c0-8a8d-2e247173db7e","value":{}}
      ]
    }$$::jsonb,
    1596480263662134,
    'PUBLIC'::securityclassification,
    TIMESTAMP '2020-08-03 18:44:23.623',
    NULL
);

INSERT INTO case_data (
    id,
    created_date,
    last_modified,
    jurisdiction,
    case_type_id,
    state,
    last_state_modified_date,
    data,
    data_classification,
    reference,
    security_classification,
    supplementary_data,
    marked_by_logstash
) VALUES (
    9999993,
    NOW(),
    NOW(),
    'SSCS',
    'Benefit',
    'appealCreated',
    NOW(),
    '{
      "activeHearingId": "abc"
    }'::jsonb,
    '{}'::jsonb,
    9999993,
    'PUBLIC',
    NULL,
    false
);