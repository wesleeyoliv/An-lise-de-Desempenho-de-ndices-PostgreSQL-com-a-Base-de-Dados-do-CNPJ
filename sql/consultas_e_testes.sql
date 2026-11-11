-- Script DDL para criar a estrutura da Base CNPJ (2023) no PostgreSQL (pgAdmin)

-- 1. Criação da tabela EMPRESAS (A entidade principal e central)
CREATE TABLE empresas (
    cnpj_basico VARCHAR(8) PRIMARY KEY,
    razao_social VARCHAR(255),
    natureza_juridica VARCHAR(4),
    qualificacao_responsavel VARCHAR(2),
    capital_social NUMERIC(15, 2),
    porte_empresa VARCHAR(2)
);

-- 2. Criação da tabela ESTABELECIMENTOS (Matriz e Filiais)
-- Relacionamento 1:N com EMPRESAS
CREATE TABLE estabelecimentos (
    cnpj_basico VARCHAR(8),
    cnpj_ordem VARCHAR(4),
    cnpj_dv VARCHAR(2),
    identificador_matriz_filial VARCHAR(1), -- Ex: 1 para matriz, 2 para filial
    nome_fantasia VARCHAR(255),
    situacao_cadastral VARCHAR(2),
    data_inicio_atividade DATE,
    cnae_fiscal_principal VARCHAR(7),
    uf VARCHAR(2),
    municipio VARCHAR(4), -- Código IBGE ou Tomador
    
    -- A Chave Primária Composta representa o CNPJ completo de 14 dígitos
    PRIMARY KEY (cnpj_basico, cnpj_ordem, cnpj_dv),
    
    -- Chave Estrangeira ligando à tabela EMPRESAS
    CONSTRAINT fk_estabelecimentos_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico)
);

-- 3. Criação da tabela SOCIOS
-- Relacionamento 1:N com EMPRESAS
CREATE TABLE socios (
    id_socio SERIAL PRIMARY KEY, -- ID sequencial próprio para identificar cada registro de forma única
    cnpj_basico VARCHAR(8),
    nome_socio VARCHAR(255),
    cnpj_cpf_socio VARCHAR(14),
    qualificacao_socio VARCHAR(2),
    data_entrada_sociedade DATE,
    faixa_etaria VARCHAR(1),
    
    -- Chave Estrangeira ligando à tabela EMPRESAS
    CONSTRAINT fk_socios_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico)
);

SELECT * FROM empresas LIMIT 1000;
ALTER TABLE estabelecimentos DISABLE TRIGGER ALL;
-- Rode a carga no Pentaho aqui
ALTER TABLE estabelecimentos ENABLE TRIGGER ALL;
TRUNCATE TABLE estabelecimentos, empresas, socios CASCADE;
TRUNCATE TABLE estabelecimentos, empresas, socios CASCADE;

ALTER TABLE estabelecimentos DROP CONSTRAINT IF EXISTS fk_estabelecimentos_empresas;

SELECT * FROM estabelecimentos LIMIT 100;
TRUNCATE TABLE estabelecimentos;

SELECT municipio, count(*) as total 
FROM estabelecimentos 
GROUP BY municipio 
ORDER BY total DESC 
LIMIT 10;

SELECT count(*) FROM socios;
TRUNCATE TABLE estabelecimentos RESTART IDENTITY CASCADE;
ALTER TABLE estabelecimentos DROP COLUMN data_inicio_atividade;


-- Ajustando as colunas reais da tabela estabelecimentos
ALTER TABLE estabelecimentos ALTER COLUMN municipio TYPE VARCHAR(50);
ALTER TABLE estabelecimentos ALTER COLUMN cnae_fiscal_principal TYPE VARCHAR(20);

TRUNCATE TABLE estabelecimentos;
SELECT cnpj_basico, cnpj_ordem, cnpj_dv,  municipio 
FROM estabelecimentos 
LIMIT 10000;


-- Ajustando tamanhos para colunas que costumam dar problema em Sócios

ALTER TABLE socios ALTER COLUMN cpf_cnpj_socio TYPE VARCHAR(20);
ALTER TABLE socios ALTER COLUMN representante_legal TYPE VARCHAR(150);


-- Ajustando para o que realmente existe na tua tabela
ALTER TABLE socios ALTER COLUMN nome_socio TYPE VARCHAR(500);

-- 1. Renomeia a tabela atual para não perder nada por enquanto
ALTER TABLE socios RENAME TO socios_old;

-- 2. Cria a tabela nova com a ordem EXATA que você pediu
CREATE TABLE socios (
    id_socio SERIAL PRIMARY KEY,
    cnpj_basico VARCHAR(8),
    faixa_etaria VARCHAR(1),
    nome_socio VARCHAR(500), -- Já aumentei aqui para não dar erro de tamanho!
    cnpj_cpf_socio VARCHAR(14),
    qualificacao_socio VARCHAR(2),
    data_entrada_sociedade DATE,
    
    -- Mantendo a sua regra de integridade
    CONSTRAINT fk_socios_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico)
);

-- 3. Se você já tinha dados e quer mover para a nova ordem:
-- INSERT INTO socios (cnpj_basico, faixa_etaria, nome_socio, cnpj_cpf_socio, qualificacao_socio, data_entrada_sociedade)
-- SELECT cnpj_basico, faixa_etaria, nome_socio, cnpj_cpf_socio, qualificacao_socio, data_entrada_sociedade 
-- FROM socios_old;

-- 4. Se a tabela estava vazia ou você vai recarregar do zero, pode apagar a velha:
DROP TABLE socios_old;

ALTER TABLE socios DROP CONSTRAINT fk_socios_empresas;



SELECT 
    e.razao_social, 
    est.nome_fantasia, 
    est.cnpj_basico || est.cnpj_ordem || est.cnpj_dv AS cnpj,

    est.municipio,
    est.uf
FROM empresas e
JOIN estabelecimentos est ON e.cnpj_basico = est.cnpj_basico
WHERE est.nome_fantasia ILIKE '%FLAVIO AUTOMOVEIS%'
   OR (est.nome_fantasia ILIKE '%FLAVIO%' AND est.nome_fantasia ILIKE '%AUTO%');



SELECT nome_fantasia
FROM estabelecimentos
WHERE uf = 'CE' 



SELECT nome_fantasia 
FROM estabelecimentos 
WHERE uf = 'CE';


SELECT count(*) FROM estabelecimentos WHERE uf = 'CE';

-- Isso vai nos mostrar o que REALMENTE tem nas primeiras 10 linhas da tabela
SELECT cnpj_basico, nome_fantasia, uf, 
FROM estabelecimentos 
LIMIT 10;


SELECT * FROM estabelecimentos LIMIT 5;




SELECT 
    cnpj_basico, 
    razao_social, 
    natureza_juridica, 
    qualificacao_responsavel, 
    capital_social, 
    porte_empresa,
    -- Validação visual do Porte
    CASE 
        WHEN porte_empresa = '01' THEN '01 - NÃO INFORMADO'
        WHEN porte_empresa = '03' THEN '03 - MICRO EMPRESA'
        WHEN porte_empresa = '05' THEN '05 - EPP'
        ELSE 'CÓDIGO: ' || porte_empresa
    END AS descricao_porte
FROM empresas 
ORDER BY razao_social ASC
LIMIT 50;


SELECT 
    cnpj_basico,
    cnpj_ordem,
    cnpj_dv,
    identificador_matriz_filial,
    nome_fantasia,
    situacao_cadastral,
    cnae_fiscal_principal,
    uf,
    municipio
FROM estabelecimentos 
LIMIT 2000;


TRUNCATE TABLE estabelecimentos;

SELECT 
    cnpj_basico, 
    nome_socio, 
    cnpj_cpf_socio, 
    qualificacao_socio, 
    data_entrada_sociedade,
    faixa_etaria
FROM socios 
ORDER BY data_entrada_sociedade DESC
LIMIT 50;

-- 1. Primeiro, removemos as Chaves Estrangeiras (Foreign Keys)
-- Isso é necessário para que o banco permita remover as Chaves Primárias da tabela 'empresas' depois.
ALTER TABLE estabelecimentos DROP CONSTRAINT IF EXISTS fk_estabelecimentos_empresas;
ALTER TABLE socios DROP CONSTRAINT IF EXISTS fk_socios_empresas;

-- 2. Em seguida, removemos as Chaves Primárias (Primary Keys)
-- Isso removerá os índices criados automaticamente para essas chaves.
ALTER TABLE estabelecimentos DROP CONSTRAINT IF EXISTS estabelecimentos_pkey;
ALTER TABLE socios DROP CONSTRAINT IF EXISTS socios_pkey;
ALTER TABLE empresas DROP CONSTRAINT IF EXISTS empresas_pkey;

CREATE INDEX idx_hash_uf ON estabelecimentos USING HASH(uf);





SELECT 
    cnpj_basico, 
    nome_fantasia, 
    municipio
FROM 
    estabelecimentos
WHERE 
    uf = 'CE';




EXPLAIN ANALYZE 
SELECT 
    cnpj_basico, 
    nome_fantasia, 
    municipio
FROM 
    estabelecimentos
WHERE 
    uf = 'CE';

EXPLAIN ANALYZE 
SELECT cnpj_basico, nome_fantasia, municipio 
FROM estabelecimentos 
WHERE uf = 'CE';

-- Apaga o Hash que demorou meia hora
DROP INDEX idx_hash_uf;

-- Aumenta a memória temporária para acelerar a criação do próximo
SET maintenance_work_mem = '1GB';

-- Cria o índice B-Tree (Questão 4)
CREATE INDEX idx_btree_uf ON estabelecimentos USING BTREE(uf);

EXPLAIN ANALYZE 
SELECT cnpj_basico, nome_fantasia, municipio 
FROM estabelecimentos 
WHERE uf = 'CE';

SELECT 
    cnpj_basico, 
    razao_social, 
    capital_social
FROM 
    empresas
WHERE 
    capital_social > 1000000.00;

EXPLAIN ANALYZE 
SELECT cnpj_basico, razao_social, capital_social 
FROM empresas 
WHERE capital_social > 1000000.00;


CREATE INDEX idx_btree_capital ON empresas USING BTREE(capital_social);

 DROP INDEX idx_btree_capital;
SET maintenance_work_mem = '1GB';
CREATE INDEX idx_hash_capital ON empresas USING HASH(capital_social);

DROP INDEX IF EXISTS idx_btree_capital;
SET maintenance_work_mem = '1GB';
CREATE INDEX idx_hash_capital ON empresas USING HASH(capital_social);

SELECT 
    e.razao_social, 
    est.nome_fantasia, 
    est.municipio
FROM 
    empresas e, estabelecimentos est
WHERE 
    e.cnpj_basico = est.cnpj_basico;



	-- Dá um fôlego extra de memória para o banco
SET maintenance_work_mem = '1GB';

-- Tenta criar o Hash na PK da tabela A (empresas)
CREATE INDEX idx_hash_empresas_pk ON empresas USING HASH(cnpj_basico);


EXPLAIN ANALYZE 
SELECT e.razao_social, est.nome_fantasia, est.municipio 
FROM empresas e, estabelecimentos est 
WHERE e.cnpj_basico = est.cnpj_basico;




-- Dá o fôlego de memória
SET maintenance_work_mem = '1GB';

-- Cria o índice Hash na FK da tabela B (estabelecimentos)
CREATE INDEX idx_hash_estab_fk ON estabelecimentos USING HASH(cnpj_basico);




EXPLAIN ANALYZE 
SELECT e.razao_social, est.nome_fantasia, est.municipio 
FROM empresas e, estabelecimentos est 
WHERE e.cnpj_basico = est.cnpj_basico;


SELECT uf, COUNT(*) as total
FROM estabelecimentos
GROUP BY uf;






-- 1. Limpando o terreno (apagando os índices que criamos nas fases 1 e 3)
DROP INDEX IF EXISTS idx_btree_uf;
DROP INDEX IF EXISTS idx_hash_uf;
DROP INDEX IF EXISTS idx_hash_estab_fk;

-- 2. Rodando a Consulta de Agregação (Questão 1)
EXPLAIN ANALYZE 
SELECT uf, COUNT(*) as total
FROM estabelecimentos
GROUP BY uf;



-- Dá o fôlego de memória
SET maintenance_work_mem = '1GB';

-- Cria o índice Hash no atributo uf
CREATE INDEX idx_hash_uf ON estabelecimentos USING HASH(uf);

EXPLAIN ANALYZE 
SELECT uf, COUNT(*) as total
FROM estabelecimentos
GROUP BY uf;


EXPLAIN ANALYZE 
SELECT uf, COUNT(*) as total
FROM estabelecimentos
WHERE uf = 'CE'
GROUP BY uf;






ALTER TABLE empresas DROP CONSTRAINT IF EXISTS empresas_pkey;
DROP INDEX IF EXISTS idx_btree_capital;
DROP INDEX IF EXISTS idx_hash_capital;
DROP INDEX IF EXISTS idx_hash_empresas_pk;


EXPLAIN ANALYZE 
SELECT cnpj_basico, razao_social 
FROM empresas 
WHERE cnpj_basico = '00000000';



EXPLAIN ANALYZE 
SELECT cnpj_basico, razao_social 
FROM empresas 
WHERE razao_social = 'BANCO DO BRASIL SA';




SET maintenance_work_mem = '1GB';

-- Índice para a Consulta A (Filtro na PK)
CREATE INDEX idx_hash_empresas_pk ON empresas USING HASH(cnpj_basico);

-- Índice para a Consulta B (Filtro na Não-PK)
CREATE INDEX idx_btree_empresas_razao ON empresas USING BTREE(razao_social);



-- Consulta A
EXPLAIN ANALYZE SELECT cnpj_basico, razao_social FROM empresas WHERE cnpj_basico = '00000000';

-- Consulta B
EXPLAIN ANALYZE SELECT cnpj_basico, razao_social FROM empresas WHERE razao_social = 'BANCO DO BRASIL SA';


-- 1. Garante que os índices criados nessa etapa foram apagados
DROP INDEX IF EXISTS idx_hash_empresas_pk;
DROP INDEX IF EXISTS idx_hash_estab_fk;

-- 2. Consulta Base (Questão 1 da Fase 3)
EXPLAIN ANALYZE 
SELECT e.razao_social, est.nome_fantasia, est.municipio 
FROM empresas e, estabelecimentos est 
WHERE e.cnpj_basico = est.cnpj_basico;



SET maintenance_work_mem = '1GB';
CREATE INDEX idx_hash_estab_fk ON estabelecimentos USING HASH(cnpj_basico);



EXPLAIN ANALYZE 
SELECT e.razao_social, est.nome_fantasia, est.municipio 
FROM empresas e, estabelecimentos est 
WHERE e.cnpj_basico = est.cnpj_basico 
AND e.cnpj_basico = '12345678'; -- AQUI ESTÁ O TRUQUE!


-- Contar quantas Empresas foram importadas
SELECT COUNT(*) AS total_empresas FROM empresas;

-- Contar quantos Estabelecimentos (Matrizes e Filiais) foram importados
SELECT COUNT(*) AS total_estabelecimentos FROM estabelecimentos;

-- Contar quantos Sócios foram importados
SELECT COUNT(*) AS total_socios FROM socios;





-- Ver as primeiras 10 empresas
SELECT * FROM empresas LIMIT 10;

-- Ver os primeiros 10 estabelecimentos
SELECT * FROM estabelecimentos LIMIT 10;

-- Ver os primeiros 10 sócios
SELECT * FROM socios LIMIT 10;








-- 1. Removendo todos os índices secundários (B-Tree e Hash) criados nas fases anteriores
DROP INDEX IF EXISTS idx_hash_uf;
DROP INDEX IF EXISTS idx_btree_uf;
DROP INDEX IF EXISTS idx_btree_capital;
DROP INDEX IF EXISTS idx_hash_capital;
DROP INDEX IF EXISTS idx_hash_empresas_pk;
DROP INDEX IF EXISTS idx_hash_estab_fk;
DROP INDEX IF EXISTS idx_btree_empresas_razao;

-- 2. Removendo as Chaves Estrangeiras (Foreign Keys)
-- Precisamos remover elas primeiro para não dar erro ao apagar as Primary Keys
ALTER TABLE estabelecimentos DROP CONSTRAINT IF EXISTS fk_estabelecimentos_empresas;
ALTER TABLE socios DROP CONSTRAINT IF EXISTS fk_socios_empresas;

-- 3. Removendo as Chaves Primárias (Primary Keys)
-- Remover a PK apaga automaticamente o índice principal oculto que o Postgres cria para ela
ALTER TABLE estabelecimentos DROP CONSTRAINT IF EXISTS estabelecimentos_pkey;
ALTER TABLE socios DROP CONSTRAINT IF EXISTS socios_pkey;
ALTER TABLE empresas DROP CONSTRAINT IF EXISTS empresas_pkey;


-- 1. Recriando as Chaves Primárias (Isso vai criar os índices B-Tree de forma automática para elas)
ALTER TABLE empresas ADD PRIMARY KEY (cnpj_basico);
ALTER TABLE estabelecimentos ADD PRIMARY KEY (cnpj_basico, cnpj_ordem, cnpj_dv);
ALTER TABLE socios ADD PRIMARY KEY (id_socio);

-- 2. Recriando as Chaves Estrangeiras (Garante o relacionamento)
ALTER TABLE estabelecimentos 
ADD CONSTRAINT fk_estabelecimentos_empresas 
FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

ALTER TABLE socios 
ADD CONSTRAINT fk_socios_empresas 
FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);



ALTER TABLE empresas ADD PRIMARY KEY (cnpj_basico);
ALTER TABLE estabelecimentos ADD PRIMARY KEY (cnpj_basico, cnpj_ordem, cnpj_dv);

ALTER TABLE estabelecimentos ADD CONSTRAINT fk_estabelecimentos_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

ALTER TABLE socios ADD CONSTRAINT fk_socios_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

DELETE FROM estabelecimentos WHERE cnpj_basico = '00000000';
DELETE FROM socios WHERE cnpj_basico = '00000000';







ALTER TABLE estabelecimentos ADD CONSTRAINT fk_estabelecimentos_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

ALTER TABLE socios ADD CONSTRAINT fk_socios_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);





-- 1. Limpa todas as filiais órfãs
DELETE FROM estabelecimentos est
WHERE NOT EXISTS (
    SELECT 1 FROM empresas e WHERE e.cnpj_basico = est.cnpj_basico
);

-- 2. Limpa todos os sócios órfãos
DELETE FROM socios s
WHERE NOT EXISTS (
    SELECT 1 FROM empresas e WHERE e.cnpj_basico = s.cnpj_basico
);







ALTER TABLE estabelecimentos ADD CONSTRAINT fk_estabelecimentos_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

ALTER TABLE socios ADD CONSTRAINT fk_socios_empresas FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);







-- Dá um fôlego extra de memória para o banco criar os índices mais rápido
SET maintenance_work_mem = '1GB';

-- 1. Índice B-Tree para buscas textuais (Cenário 2)
-- ATENÇÃO: Adicionado 'varchar_pattern_ops' para que o B-Tree funcione com o comando LIKE no PostgreSQL
CREATE INDEX idx_btree_empresas_razao ON empresas USING BTREE(razao_social varchar_pattern_ops);
CREATE INDEX idx_btree_estab_nome ON estabelecimentos USING BTREE(nome_fantasia varchar_pattern_ops);

-- 2. Índice Hash para filtros exatos geográficos (Cenário 3)
CREATE INDEX idx_hash_estab_uf ON estabelecimentos USING HASH(uf);

-- 3. Índices para sustentar os Joins pesados nas Foreign Keys (Cenário 4)
-- Optamos por Hash aqui porque o cruzamento entre tabelas é feito por igualdade exata de CNPJ
CREATE INDEX idx_hash_estab_fk_cnpj ON estabelecimentos USING HASH(cnpj_basico);
CREATE INDEX idx_hash_socios_fk_cnpj ON socios USING HASH(cnpj_basico);

-- 4. Índice B-Tree para ordenação e filtro de valores (Cenário 5)
CREATE INDEX idx_btree_empresas_capital ON empresas USING BTREE(capital_social);











-- Cenário 1: Testando a Chave Primária Oculta (B-Tree)
EXPLAIN ANALYZE 
SELECT cnpj_basico, cnpj_ordem, nome_fantasia 
FROM estabelecimentos 
WHERE cnpj_basico = '00000000' AND cnpj_ordem = '0001';

-- Cenário 2: Testando a Busca Textual (Índice B-Tree de Razão Social)
EXPLAIN ANALYZE 
SELECT cnpj_basico, razao_social 
FROM empresas 
WHERE razao_social LIKE 'BANCO DO BRASIL%';

-- Cenário 3: Testando a Busca Geográfica (Índice Hash de UF)
EXPLAIN ANALYZE 
SELECT municipio, count(*) 
FROM estabelecimentos 
WHERE uf = 'CE'
GROUP BY municipio;

-- Cenário 4: Testando o Join Relacional Pesado (Índice Hash na FK)
EXPLAIN ANALYZE 
SELECT e.razao_social, s.nome_socio 
FROM empresas e
JOIN socios s ON e.cnpj_basico = s.cnpj_basico
WHERE e.cnpj_basico = '00000000';

-- Cenário 5: Testando o Filtro Numérico por Faixa (Índice B-Tree de Capital)
EXPLAIN ANALYZE 
SELECT razao_social, capital_social 
FROM empresas 
WHERE capital_social > 10000000.00;




-- Cenário 1: Ver os dados da Busca Exata
SELECT cnpj_basico, cnpj_ordem, cnpj_dv, nome_fantasia, municipio, uf 
FROM estabelecimentos 
WHERE cnpj_basico = '00000000' AND cnpj_ordem = '0001';

-- Cenário 2: Ver a Busca Textual funcionando
SELECT cnpj_basico, razao_social, natureza_juridica 
FROM empresas 
WHERE razao_social LIKE 'BANCO DO BRASIL%'
LIMIT 100;

-- Cenário 3: Ver a Aglomeração Geográfica no Ceará
SELECT municipio, count(*) as total_filiais 
FROM estabelecimentos 
WHERE uf = 'CE'
GROUP BY municipio
ORDER BY total_filiais DESC;

-- Cenário 4: Ver o cruzamento das matrizes com seus sócios
SELECT e.cnpj_basico, e.razao_social, s.nome_socio, s.qualificacao_socio 
FROM empresas e
JOIN socios s ON e.cnpj_basico = s.cnpj_basico
WHERE e.cnpj_basico = '00000000';


-- Cenário 5: Ver a lista de Empresas de Alto Capital Social
SELECT cnpj_basico, razao_social, capital_social, porte_empresa
FROM empresas 
WHERE capital_social > 10000000.00
ORDER BY capital_social DESC
LIMIT 100;









SELECT cnpj_basico, nome_fantasia, uf 
FROM estabelecimentos 
WHERE nome_fantasia IS NOT NULL
LIMIT 300;



SELECT cnpj_basico, nome_socio 
FROM socios 
LIMIT 300;


-- Cenário 1: Busca Exata 
-- (Pegamos o CNPJ da "OTICA PERFEICAO" que está na linha 2 do seu arquivo de filiais)
SELECT cnpj_basico, nome_fantasia, uf 
FROM estabelecimentos 
WHERE cnpj_basico = '03650261';
-- Cenário 2: Busca Textual
-- (Pegamos o começo do nome da "COMERCIAL KARAJAS" que está na linha 5 do seu arquivo de empresas)
SELECT cnpj_basico, razao_social, capital_social 
FROM empresas 
WHERE razao_social LIKE 'COMERCIAL KARAJAS%';
-- Cenário 3: Agrupamento Geográfico
-- (Pegamos 'RR' e 'AP' pois são estados com menos registros. Se usarmos 'SP', o banco fará Seq Scan 
-- porque a quantidade de linhas é muito grande, sendo mais rápido ler a tabela toda!)
SELECT uf, count(*) as total_filiais 
FROM estabelecimentos 
WHERE uf IN ('RR', 'AP')
GROUP BY uf
ORDER BY total_filiais DESC;
-- Cenário 4: O Cruzamento Pesado (JOIN)
-- (Vamos cruzar a "OTICA PERFEICAO" com a tabela de Sócios, pois vi o "DILTO DE SOUZA" lá no arquivo)
SELECT e.cnpj_basico, e.nome_fantasia, s.nome_socio 
FROM estabelecimentos e
JOIN socios s ON e.cnpj_basico = s.cnpj_basico
WHERE e.cnpj_basico = '03650261';
-- Cenário 5: Filtro Numérico por Faixa de Capital
-- (No seu arquivo de empresas, vi capitais como 100.000, 240.000, etc. Vamos buscar os tubarões!)
SELECT cnpj_basico, razao_social, capital_social 
FROM empresas 
WHERE capital_social > 100000.00
ORDER BY capital_social DESC
LIMIT 50;
