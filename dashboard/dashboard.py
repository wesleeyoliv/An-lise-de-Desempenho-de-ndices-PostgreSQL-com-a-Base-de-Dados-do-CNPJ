import streamlit as st
import pandas as pd
import psycopg2
import plotly.express as px

# Configuração da Página
st.set_page_config(page_title="Dashboard CNPJ 2023", layout="wide", page_icon="📊")

# --- CONEXÃO COM O BANCO DE DADOS ---
# ATENÇÃO: Substitua as informações abaixo com as credenciais do seu pgAdmin!
@st.cache_resource
def init_connection():
    return psycopg2.connect(
        host="localhost",        # Geralmente é localhost
        port="5432",             # Porta padrão do Postgres
        database="NOME_DO_SEU_BANCO", # <--- COLOQUE O NOME DO SEU BANCO AQUI (ex: postgres, cnpj, ap2)
        user="postgres",         # Seu usuário (geralmente postgres)
        password="SUA_SENHA_AQUI"     # <--- COLOQUE SUA SENHA DO PGADMIN AQUI
    )

try:
    conn = init_connection()
except Exception as e:
    st.error(f"⚠️ Erro ao conectar ao banco de dados: Verifique se o nome do banco e a senha estão corretos no código.\nErro técnico: {e}")
    st.stop()

# Função para executar query e retornar dataframe do Pandas
def run_query(query, params=None):
    with conn.cursor() as cur:
        cur.execute(query, params)
        colnames = [desc[0] for desc in cur.description]
        data = cur.fetchall()
        return pd.DataFrame(data, columns=colnames)

# --- INTERFACE DO DASHBOARD ---
st.title("📊 Painel Interativo - Análise de Dados CNPJ 2023")
st.markdown("Utilize o menu lateral para executar as consultas e visualizar os indicadores chave do projeto AP2.")

# Barra lateral para navegação
st.sidebar.header("Navegação e Filtros")
opcao = st.sidebar.selectbox(
    "Selecione o Indicador:",
    (
        "1. Ficha Cadastral (Busca Exata)",
        "2. Busca Textual por Empresa",
        "3. Densidade de Filiais por UF",
        "4. Quadro Societário (Join)",
        "5. Análise de Capital Social"
    )
)

st.divider()

# ==========================================
# CENÁRIO 1: BUSCA EXATA
# ==========================================
if opcao == "1. Ficha Cadastral (Busca Exata)":
    st.subheader("🏢 1. Ficha Cadastral (Busca direta por CNPJ)")
    cnpj_input = st.text_input("Digite o CNPJ Básico (Apenas os 8 primeiros dígitos):", "03650261")
    
    if st.button("Buscar no Banco", type="primary"):
        query = """
        SELECT cnpj_basico, cnpj_ordem, cnpj_dv, nome_fantasia, uf, municipio 
        FROM estabelecimentos 
        WHERE cnpj_basico = %s;
        """
        df = run_query(query, (cnpj_input,))
        if not df.empty:
            st.success(f"Consulta finalizada em milissegundos via Índice B-Tree (PK)!")
            st.dataframe(df, use_container_width=True)
        else:
            st.warning("Nenhum estabelecimento encontrado com este CNPJ Básico.")

# ==========================================
# CENÁRIO 2: BUSCA TEXTUAL
# ==========================================
elif opcao == "2. Busca Textual por Empresa":
    st.subheader("🔍 2. Busca de Empresa por Nome/Razão Social")
    nome_input = st.text_input("Digite uma palavra do nome da Empresa:", "COMERCIAL")
    
    if st.button("Buscar no Banco", type="primary"):
        query = """
        SELECT cnpj_basico, razao_social, capital_social, porte_empresa 
        FROM empresas 
        WHERE razao_social ILIKE %s
        LIMIT 100;
        """
        # Adiciona % ao redor do texto para buscar no meio das palavras
        df = run_query(query, (f"%{nome_input}%",))
        st.write(f"Resultados encontrados: {len(df)} (Limitado a 100 para não travar a tela)")
        st.dataframe(df, use_container_width=True)

# ==========================================
# CENÁRIO 3: GRÁFICO / AGRUPAMENTO
# ==========================================
elif opcao == "3. Densidade de Filiais por UF":
    st.subheader("🗺️ 3. Densidade Geográfica de Filiais por Estado")
    uf_lista = ['AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO']
    ufs_selecionadas = st.multiselect("Filtro Interativo - Selecione os Estados (UF):", uf_lista, default=['SP', 'SC', 'PR', 'CE', 'MG'])
    
    if st.button("Gerar Indicador (Gráfico)", type="primary"):
        if ufs_selecionadas:
            # Cria os %s dinamicamente dependendo de quantos estados foram selecionados
            placeholders = ', '.join(['%s'] * len(ufs_selecionadas))
            query = f"""
            SELECT uf, count(*) as total_filiais 
            FROM estabelecimentos 
            WHERE uf IN ({placeholders})
            GROUP BY uf
            ORDER BY total_filiais DESC;
            """
            df = run_query(query, tuple(ufs_selecionadas))
            
            # Dividindo a tela em duas colunas para ficar elegante
            col1, col2 = st.columns([1, 2])
            
            with col1:
                st.write("Dados da Consulta:")
                st.dataframe(df, use_container_width=True)
            
            with col2:
                # Gráfico gerado automaticamente pelo Plotly
                fig = px.bar(df, x='uf', y='total_filiais', text='total_filiais', 
                             title="Distribuição de Filiais nos Estados Selecionados",
                             labels={'uf': 'Unidade Federativa (UF)', 'total_filiais': 'Total de Filiais'},
                             color='total_filiais', color_continuous_scale='Blues')
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.error("Selecione ao menos um Estado no filtro acima.")

# ==========================================
# CENÁRIO 4: JOIN RELACIONAL
# ==========================================
elif opcao == "4. Quadro Societário (Join)":
    st.subheader("🤝 4. Investigação Societária (Cruzamento de Tabelas via FK)")
    st.markdown("Esta aba executa um `JOIN` pesado no banco otimizado pelos índices criados no Passo 4.")
    cnpj_input = st.text_input("Digite o CNPJ Básico da Matriz:", "03650261")
    
    if st.button("Analisar Sócios", type="primary"):
        query = """
        SELECT e.cnpj_basico, e.razao_social, s.nome_socio, s.qualificacao_socio, s.data_entrada_sociedade 
        FROM empresas e
        JOIN socios s ON e.cnpj_basico = s.cnpj_basico
        WHERE e.cnpj_basico = %s;
        """
        df = run_query(query, (cnpj_input,))
        if not df.empty:
            st.success(f"Razão Social da Empresa: **{df['razao_social'][0]}**")
            st.write("Quadro de Sócios e Administradores (QSA):")
            # Mostra apenas as colunas dos sócios para ficar limpo
            st.dataframe(df[['nome_socio', 'qualificacao_socio', 'data_entrada_sociedade']], use_container_width=True)
        else:
            st.warning("Não há registro de sócios para este CNPJ, ou o CNPJ não existe na tabela matriz.")

# ==========================================
# CENÁRIO 5: FAIXA DE VALORES
# ==========================================
elif opcao == "5. Análise de Capital Social":
    st.subheader("💰 5. Prospecção por Faixa de Capital Social")
    st.markdown("Filtro por operadores matemáticos otimizado pelo índice B-Tree em capital_social.")
    
    valor_min = st.number_input("Selecione o Capital Social Mínimo (R$):", min_value=0.0, value=100000.0, step=10000.0)
    
    if st.button("Filtrar Gigantes", type="primary"):
        query = """
        SELECT cnpj_basico, razao_social, capital_social 
        FROM empresas 
        WHERE capital_social >= %s
        ORDER BY capital_social DESC
        LIMIT 50;
        """
        df = run_query(query, (valor_min,))
        
        if not df.empty:
            st.write(f"Top empresas encontradas com capital acima de R$ {valor_min:,.2f}:")
            
            # Gráfico de barras horizontais
            fig = px.bar(df.head(10), y='razao_social', x='capital_social', orientation='h',
                         title="Top 10 Maiores Capitais da Busca",
                         labels={'razao_social': 'Empresa', 'capital_social': 'Capital (R$)'},
                         color='capital_social', color_continuous_scale='Viridis')
            fig.update_layout(yaxis={'categoryorder':'total ascending'})
            
            st.plotly_chart(fig, use_container_width=True)
            st.dataframe(df, use_container_width=True)
        else:
            st.warning("Nenhuma empresa encontrada com este montante de capital social.")
