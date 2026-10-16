# Simulated SAP: data model

SAP keeps its own data model with SAP's own table and field names. The SAP System API translates
it to the platform's contract; nobody else reads it (ADR 0007). Cosmos DB account
`cosmos-intplat-sap`, database `sap`, partition key `/id` everywhere.

| Container | SAP table | Holds |
|---|---|---|
| `VBAK` | Sales document header (with its items, VBAP) | The sales order created from an order |
| `VBRK` | Billing document header | The invoice of a sales order |
| `Payment` | Incoming payment (simplified) | Money received against an invoice |
| `NumberRange` | Number ranges | Next sales order (8000043217 first) and invoice (90004711 first) number |

```mermaid
erDiagram
    VBAK {
        string id PK "VBELN: 8000043217"
        string BSTKD "customer reference: the platform's orderId 4711"
        string KUNNR "sold-to customer: ACME"
        string STATUS "accepted or refused (credit check)"
        string ABGRU "rejection reason"
        number NETWR "net value"
        string WAERK "currency"
        list VBAP "items: POSNR, MATNR, KWMENG, NETPR"
        datetime ERDAT "created"
    }
    VBRK {
        string id PK "VBELN: 90004711"
        string VGBEL "the sales order"
        string KUNRG "payer"
        number NETWR "amount"
        string WAERK "currency"
        string STATUS "open or paid"
        datetime FKDAT "billing date"
        date ZFBDT "due date"
    }
    Payment {
        string id PK "payment document"
        string REBZG "the invoice"
        number WRBTR "amount"
        string WAERS "currency"
        datetime BUDAT "posting date"
    }
    NumberRange {
        string id PK "VBAK or VBRK"
        integer last
    }
    VBAK ||--o| VBRK : "billed by"
    VBRK ||--o{ Payment : "paid by"
```

The credit check is simulated: an order above 250,000 (in its currency) is refused.
