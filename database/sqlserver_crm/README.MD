# 📝 QUERIES ESENCIALES - MEMORIZAR PARA LA REVISIÓN

## ⚠️ IMPORTANTE
El profesor advirtió: **"No se extrañen si les pido que escriban el select en caliente"**

Estos son los queries que TODOS deben poder escribir de memoria durante la revisión.

---

## 1. LINKED SERVER

### Desde PromptCRM → PromptAds
```sql
-- Ver campañas desde CRM
SELECT * FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns

-- Con filtros
SELECT name, startsAt, endsAt, businessId 
FROM PROMPTADS_LINK.PromptAds.dbo.PACampaigns
WHERE enabled = 1
```

### Desde PromptAds → PromptCRM  
```sql
-- Ver clientes desde Ads
SELECT * FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes

-- Con JOIN
SELECT c.nombreEmpresa, COUNT(*) as total
FROM PROMPTCRM_LINK.PromptCRM.dbo.clientes c
GROUP BY c.nombreEmpresa
```

---

## 2. CIFRADO X.509

### INSERT con cifrado
```sql
INSERT INTO clientes (
    tipoClienteId,
    estadoClienteId, 
    identificacionEncrypted,
    nombreEmpresa
) 
VALUES (
    1,
    1,
    dbo.fn_CifrarIdentificacion('123-4567890-1'),
    'Empresa Demo'
)
```

### SELECT con descifrado
```sql
SELECT 
    clienteId,
    dbo.fn_DescifrarIdentificacion(identificacionEncrypted) AS identificacion,
    nombreEmpresa,
    nombreContacto
FROM clientes
WHERE deleted = 0
```

### UPDATE con cifrado
```sql
UPDATE clientes 
SET identificacionEncrypted = dbo.fn_CifrarIdentificacion('999-8888888-9')
WHERE clienteId = 1
```

---

## 3. QUERIES CON TVPs (Table-Valued Parameters)

### Declarar TVP
```sql
DECLARE @TestAds dbo.TVP_PAAds;

INSERT INTO @TestAds (headline, bodyText, format)
VALUES ('Oferta Black Friday', 'Descuentos 70%', 'image');
```

### Ejecutar SP con TVP
```sql
EXEC dbo.PA001SP_InsertCampaign
    @BusinessId = 1,
    @Name = 'Campaña Test',
    @StartsAt = '2025-11-20',
    @EndsAt = '2025-11-30',
    @CreatedBy_UserId = 1,
    @Ads = @TestAds
```

---

## 4. QUERIES DE PROBLEMAS DE CONCURRENCIA

### Dirty Read
```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM clientes WHERE clienteId = 1;
```

### Phantom Read
```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT COUNT(*) FROM clientes WHERE estadoClienteId = 1;
-- Otro proceso inserta
SELECT COUNT(*) FROM clientes WHERE estadoClienteId = 1;
COMMIT;
```

### Deadlock (2 sesiones)
```sql
-- Sesión 1
BEGIN TRANSACTION;
UPDATE clientes SET nombreEmpresa = 'A' WHERE clienteId = 1;
UPDATE leads SET estado = 2 WHERE leadId = 1;
COMMIT;

-- Sesión 2 (simultáneo)
BEGIN TRANSACTION;
UPDATE leads SET estado = 3 WHERE leadId = 1;
UPDATE clientes SET nombreEmpresa = 'B' WHERE clienteId = 1;
COMMIT;
```

---

## 5. QUERIES CON FUNCIONES ESPECIALES

### MERGE
```sql
MERGE PACampaignBudgetAllocations AS Target
USING @BudgetData AS Source
ON Target.campaignId = Source.campaignId
WHEN MATCHED THEN
    UPDATE SET budgetAssigned = Source.budget
WHEN NOT MATCHED THEN
    INSERT (campaignId, budgetAssigned)
    VALUES (Source.campaignId, Source.budget);
```

### CTE Recursivo
```sql
WITH HierarquiaClientes AS (
    SELECT clienteId, parentId, 1 as Nivel
    FROM clientes WHERE parentId IS NULL
    UNION ALL
    SELECT c.clienteId, c.parentId, h.Nivel + 1
    FROM clientes c
    INNER JOIN HierarquiaClientes h ON c.parentId = h.clienteId
)
SELECT * FROM HierarquiaClientes;
```

### PARTITION BY
```sql
SELECT 
    clienteId,
    fechaInteraccion,
    ROW_NUMBER() OVER (PARTITION BY clienteId ORDER BY fechaInteraccion DESC) as Orden
FROM interacciones;
```

### INTERSECT / EXCEPT
```sql
-- Clientes que tienen interacciones pero no conversiones
SELECT clienteId FROM interacciones
EXCEPT
SELECT clienteId FROM conversiones_lead;

-- Clientes con ambas
SELECT clienteId FROM interacciones
INTERSECT
SELECT clienteId FROM conversiones_lead;
```

---

## 6. VISTAS PARA ETL

### Crear vista con SCHEMABINDING
```sql
CREATE VIEW vw_resumen_clientes
WITH SCHEMABINDING
AS
SELECT 
    c.clienteId,
    COUNT_BIG(*) as total,
    SUM(valor) as suma
FROM dbo.clientes c
INNER JOIN dbo.interacciones i ON c.clienteId = i.clienteId
GROUP BY c.clienteId;
```

### Crear índice en vista
```sql
CREATE UNIQUE CLUSTERED INDEX idx_vw_resumen
ON vw_resumen_clientes(clienteId);
```

---

## 7. CONFIGURACIÓN BÁSICA

### Master Key
```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword2024!';
```

### Certificate
```sql
CREATE CERTIFICATE CertificadoPromptCRM
WITH SUBJECT = 'Certificado para cifrado',
     EXPIRY_DATE = '2030-12-31';
```

### Symmetric Key
```sql
CREATE SYMMETRIC KEY SymKey_ClienteData
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoPromptCRM;
```

---

## 📌 TIPS PARA LA REVISIÓN:

1. **Linked Server**: Recuerda el formato `[SERVER].[DB].[schema].[tabla]`
2. **Cifrado**: Las funciones se llaman `fn_CifrarIdentificacion` y `fn_DescifrarIdentificacion`
3. **TVPs**: Siempre declara primero, luego INSERT, luego ejecuta SP
4. **Isolation Levels**: READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE
5. **CTEs**: Siempre empiezan con `;WITH` si hay código antes
