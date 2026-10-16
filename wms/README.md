# Simulated WMS: data model

The warehouse management system keeps stock per warehouse and product, and a reservation per
order. Cosmos DB account `cosmos-intplat-wms`, database `wms`, partition key `/id` everywhere. Only
the WMS System API reads it (ADR 0007).

```mermaid
erDiagram
    StockItem {
        string id PK "BRU-1|SKU-1042"
        string warehouse "BRU-1"
        string sku "SKU-1042"
        integer onHand "units in the warehouse"
        integer reserved "units promised to orders"
    }
    Reservation {
        string id PK "RSV-4711"
        string orderRef "the platform's orderId"
        string warehouse "BRU-1"
        list lines "sku, qty"
        string state "RESERVED"
        datetime createdAt
    }
    StockItem ||--o{ Reservation : "reserved by (sku)"
```

A product the WMS has never seen starts with 1,000 units in warehouse `BRU-1`: the simulation never
runs dry, unless an order asks for more than is left.
