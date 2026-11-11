-- =============================================================================
-- BASE DE DADOS CNPJ — SCRIPT DIDÁTICO PARA ESTUDO COMPLETO
-- PostgreSQL | Modelagem, Saneamento, Integridade e Índices
-- =============================================================================
-- Este script engloba o ciclo de vida completo de engenharia de dados real:
--   1. Criação Inicial das Tabelas (Sem amarras de chaves estrangeiras)
--   2. Higienização Ativa (Exclusão de Registros Órfãos da amostragem)
--   3. Aplicação Segura da Integridade Referencial (Foreign Keys)
--   4. Criação dos Índices Físicos Avançados (B-Tree e Hash)
--   5. Auditoria de Performance com EXPLAIN ANALYZE
-- =============================================================================


-- =============================================================================
-- PARTE 1 — CRIAÇÃO DAS TABELAS (SEM CHAVES ESTRANGEIRAS INICIAIS)
-- =============================================================================
-- Nota DBA: Em cenários reais de ETL com cargas massivas de dados, criamos 
-- as tabelas 'soltas' (sem chaves estrangeiras) para permitir a importação 
-- bruta mais rápida e evitar travamentos por bloqueio de integridade.

CREATE TABLE empresas (
    cnpj_basico          VARCHAR(8)     PRIMARY KEY,
    razao_social         VARCHAR(255),
    natureza_juridica    VARCHAR(4),
    qualificacao_responsavel VARCHAR(2),
    capital_social       NUMERIC(15, 2),
    porte_empresa        VARCHAR(2)
);

CREATE TABLE estabelecimentos (
    cnpj_basico          VARCHAR(8),
    cnpj_ordem           VARCHAR(4),
    cnpj_dv              VARCHAR(2),
    identificador_matriz_filial VARCHAR(1),
    nome_fantasia        VARCHAR(255),
    situacao_cadastral   VARCHAR(2),
    cnae_fiscal_principal VARCHAR(20),
    uf                   VARCHAR(2),
    municipio            VARCHAR(50),
    PRIMARY KEY (cnpj_basico, cnpj_ordem, cnpj_dv)
);

CREATE TABLE socios (
    id_socio             SERIAL         PRIMARY KEY,
    cnpj_basico          VARCHAR(8),
    nome_socio           VARCHAR(500),
    cnpj_cpf_socio       VARCHAR(14),
    qualificacao_socio   VARCHAR(2),
    data_entrada_sociedade DATE,
    faixa_etaria         VARCHAR(1)
);


-- =============================================================================
-- PARTE 2 — SANEAMENTO DE DADOS (LIMPEZA DE ÓRFÃOS)
-- =============================================================================
-- Como utilizamos uma amostra de dados abertos governamentais particionados, 
-- é natural que existam filiais e sócios cujas matrizes não vieram no lote
-- importado. Se tentarmos aplicar o relacionamento agora, o banco recusa.
-- Solução: Deletar tudo que for órfão cruzando as tabelas com NOT EXISTS.

-- 1. Expurgar estabelecimentos (filiais) que não têm matriz na tabela empresas
DELETE FROM estabelecimentos est 
WHERE NOT EXISTS (
    SELECT 1 FROM empresas e WHERE e.cnpj_basico = est.cnpj_basico
);

-- 2. Expurgar sócios cujas empresas não constam na base
DELETE FROM socios s 
WHERE NOT EXISTS (
    SELECT 1 FROM empresas e WHERE e.cnpj_basico = s.cnpj_basico
);


-- =============================================================================
-- PARTE 3 — APLICAÇÃO DA INTEGRIDADE REFERENCIAL (CHAVES ESTRANGEIRAS)
-- =============================================================================
-- Com o terreno 100% limpo e sem anomalias, agora aplicamos as restrições ACID 
-- de Chave Estrangeira. O banco aceitará a operação com sucesso.

ALTER TABLE estabelecimentos 
ADD CONSTRAINT fk_estabelecimentos_empresas 
FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);

ALTER TABLE socios 
ADD CONSTRAINT fk_socios_empresas 
FOREIGN KEY (cnpj_basico) REFERENCES empresas (cnpj_basico);


-- =============================================================================
-- PARTE 4 — ENGENHARIA DE ÍNDICES SECUNDÁRIOS
-- =============================================================================
-- Aqui construímos os caminhos físicos de busca otimizados por algoritmo.

-- Ajuste de memória para acelerar a compilação no disco
SET maintenance_work_mem = '1GB';

-- 1. B-Tree Padrão (Ideal para buscas exatas, prefixos ordenados e desigualdades)
CREATE INDEX idx_btree_razao_social ON empresas USING BTREE(razao_social);
CREATE INDEX idx_btree_capital_social ON empresas USING BTREE(capital_social);

-- 2. Hash (Ideal para igualdade exata O(1), como Foreign Keys)
CREATE INDEX idx_hash_uf ON estabelecimentos USING HASH(uf);
CREATE INDEX idx_hash_estab_fk ON estabelecimentos USING HASH(cnpj_basico);
CREATE INDEX idx_hash_socios_fk ON socios USING HASH(cnpj_basico);


-- =============================================================================
-- PARTE 5 — CONSULTAS DE TESTE COM EXPLAIN ANALYZE
-- =============================================================================

-- CENÁRIO 1 — Busca Exata (Chave Primária Composta - B-Tree Oculto nativo)
EXPLAIN ANALYZE
SELECT cnpj_basico, cnpj_ordem, nome_fantasia, uf
FROM estabelecimentos
WHERE cnpj_basico = '00000000' AND cnpj_ordem  = '0001';

-- CENÁRIO 2 — Busca Textual de Prospectos (B-Tree Padrão de igualdade)
EXPLAIN ANALYZE
SELECT cnpj_basico, razao_social
FROM empresas
WHERE razao_social = 'BANCO DO BRASIL SA';

-- CENÁRIO 3 — Filtro Geográfico em Região de Baixa Densidade (Bitmap Index Scan Hash)
EXPLAIN ANALYZE
SELECT municipio, COUNT(*) AS total
FROM estabelecimentos
WHERE uf IN ('RR', 'AP')
GROUP BY municipio
ORDER BY total DESC;

-- CENÁRIO 4 — JOIN Relacional Cruzando Matriz e Sócios (Index Scan Hash O(1))
EXPLAIN ANALYZE
SELECT e.razao_social, s.nome_socio, s.qualificacao_socio
FROM empresas e
JOIN socios s ON e.cnpj_basico = s.cnpj_basico
WHERE e.cnpj_basico = '03650261';

-- CENÁRIO 5 — Filtro Numérico por Faixa (Index Scan Backward B-Tree)
EXPLAIN ANALYZE
SELECT razao_social, capital_social
FROM empresas
WHERE capital_social > 10000000.00
ORDER BY capital_social DESC
LIMIT 50;
