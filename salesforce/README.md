# Simulated Salesforce: data model

Salesforce keeps its own data model, with Salesforce's own naming: standard fields in
PascalCase, custom fields ending in `__c`. The Salesforce System API translates it to the
platform's contract; nobody else reads it (ADR 0007).

## `Order` (container `Order`, partition key `/id`)

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Salesforce record id, e.g. `801Ad0000004711AAA` |
| `OrderNumber` | string | Auto-number, e.g. `4711` (the order id the platform uses) |
| `AccountId` | string | The customer account, e.g. `ACME` |
| `Status` | string | Salesforce's own status: `Draft`, `Activated` or `Cancelled` |
| `Order_Status__c` | string | The order domain's status (placed, confirmed, onHold, cancelled, …) |
| `Payment_Status__c` | string | unpaid, invoiced, paid |
| `Channel__c` | string | salesforce, webshop, agent |
| `OrderItems` | array | `{ OrderItemNumber, Product2Id, Quantity, UnitPrice }` |
| `CurrencyIsoCode` | string | ISO 4217 |
| `TotalAmount` | number | Sum of the items |
| `ShippingStreet`, `ShippingPostalCode`, `ShippingCity`, `ShippingCountryCode` | string | Delivery address (Salesforce flattens addresses) |
| `Requested_Delivery_Date__c` | string | ISO 8601 date |
| `Hold_Reason__c`, `Cancellation_Reason__c` | string | Set when held or cancelled |
| `Idempotency_Key__c` | string | Key of the request that created the order |
| `ERP_Order_Number__c`, `Invoice_Number__c`, `Credit_Note_Number__c` | string | SAP's sales order, invoice and credit note for this order |
| `Reservation_Id__c`, `Warehouse__c` | string | The WMS reservation and its warehouse |
| `Shipment_Id__c`, `Tracking_Number__c`, `Logistics_Partner__c` | string | The 3PL consignment |
| `Order_Milestones__r` | array | Related list `{ Fact__c, Domain__c, Occurred_At__c }`: every business fact about the order |
| `CreatedDate`, `LastModifiedDate` | string | ISO 8601, UTC |

## `Account` and `Product2` (containers `Account`, `Product2`)

Reference data, written by the System API on first read from its
[`sample_data.py`](https://github.com/azure-intelligence-domain/system-api-salesforce/blob/main/sample_data.py):
four fictional customers (`AccountNumber` = the platform's `customerid`, e.g. `ACME`) and six
products (`ProductCode` = the `productId` every domain uses, e.g. `SKU-1042`, with `StandardPrice`).

## `AutoNumber` (container `AutoNumber`)

One document `{ "id": "OrderNumber", "last": 4710 }`, incremented with optimistic concurrency
(ETag). The first order after a fresh build is **4711**.

## Diagram

```mermaid
erDiagram
    Order {
        string id PK "801Ad0000004711AAA"
        string OrderNumber "4711"
        string AccountId
        string Status
        string Order_Status__c
        string Payment_Status__c
        string Channel__c
        list OrderItems
        string CurrencyIsoCode
        number TotalAmount
        string ShippingStreet
        string ShippingPostalCode
        string ShippingCity
        string ShippingCountryCode
        string Requested_Delivery_Date__c
        string Hold_Reason__c
        string Cancellation_Reason__c
        string Idempotency_Key__c
        string ERP_Order_Number__c
        string Invoice_Number__c
        string Credit_Note_Number__c
        string Reservation_Id__c
        string Shipment_Id__c
        string Tracking_Number__c
        datetime CreatedDate
        datetime LastModifiedDate
    }
    OrderItem {
        integer OrderItemNumber
        string Product2Id
        integer Quantity
        number UnitPrice
    }
    OrderMilestone {
        string Fact__c "OrderPlaced, SalesOrderAccepted, ..."
        string Domain__c "order, finance, supply, logistics"
        datetime Occurred_At__c
    }
    Account {
        string id PK "ACME"
        string AccountNumber "ACME"
        string Name
        string Industry
        string ShippingCity
        string CurrencyIsoCode
    }
    Product2 {
        string id PK "SKU-1042"
        string ProductCode "SKU-1042"
        string Name
        string Family
        number StandardPrice
        boolean IsActive
    }
    AutoNumber {
        string id PK "OrderNumber"
        integer last "4710 before the first order"
    }
    Order ||--|{ OrderItem : "OrderItems (embedded)"
    Order ||--o{ OrderMilestone : "Order_Milestones__r (embedded)"
    Account ||--o{ Order : "AccountId"
    Product2 ||--o{ OrderItem : "Product2Id"
    AutoNumber ||--o{ Order : "numbers"
```

The domain view (Account, Opportunity, Product, and how the platform's contract maps onto this
record) is in [system-api-salesforce](https://github.com/azure-intelligence-domain/system-api-salesforce#data-model-sales-domain).
