# Desafio Técnico - Infraestrutura com Docker, Terraform, PostgreSQL, Node.js, Prometheus e Grafana

Este projeto implementa uma infraestrutura **local e automatizada com Terraform** para provisionar containers Docker com as seguintes camadas:

- **Frontend**: HTML + NGINX
- **Backend**: Node.js com conexão ao PostgreSQL
- **Banco de Dados**: PostgreSQL 15.8 com volume persistente e script dinâmico
- **Observabilidade**: Prometheus, Grafana e cAdvisor

---

## Estrutura do Projeto

```bash
├── backend/
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
│
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── default.conf
│
├── sql/
│   ├── script.sql.tpl
│   └── generate_sql.sh
│
├── monitoring/
│   ├── prometheus/
            ├── Dockerfile
            ├── prometheus.yml
│   ├── grafana/
            ├── Dockerfile
            ├── grafana.ini
│
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
├── .env
├── .gitignore
└── README.md
```

---

## Requisitos

- [x] Backend acessa o banco com dados dinâmicos via script SQL
- [x] Frontend acessa o backend via NGINX proxy_pass
- [x] Infraestrutura gerenciada por **Terraform**
- [x] Redes separadas para frontend e backend
- [x] Volume persistente no PostgreSQL
- [x] Prometheus + Grafana + cAdvisor monitorando containers
- [x] Variáveis de ambiente para segredos
- [x] Alertas e dashboards no Grafana

---

## Como rodar o projeto

### 1. Clone o repositório

```bash
git clone https://github.com/DennisAJG/desafio-cubos.git
cd desafio-cubos
```

### 2. Configure as variáveis de ambiente

Crie um arquivo `.env` na raiz:

```env
DB_USER=admin
DB_PASS=secure_p4$$w0rd
DB_ROLE=admin
DB_PORT=5432
PORT=3000
```

### 3. Gere o script dinâmico do banco

```bash
cd sql/
chmod +x generate_sql.sh
./generate_sql.sh
```

### 4. Inicialize o Terraform

```bash
cd infra/
terraform init
terraform apply -auto-approve
```

---

## Endpoints

| Serviço       | URL                       |
|---------------|---------------------------|
| Frontend      | http://localhost:8080     |
| Backend API   | http://localhost:3000/api |
| PostgreSQL    | localhost:5432            |
| Prometheus    | http://localhost:9090     |
| Grafana       | http://localhost:3000     |
| Metrics API   | http://localhost:3000/metrics |

---

## Dashboards e Monitoramento

### Prometheus

- Rota para métricas do backend: `/metrics`
- Rota cAdvisor: `http://cadvisor:8080/metrics`

### Grafana

- Dashboard pronto: `Docker Monitoring import 193`
- Login padrão: `admin / admin`
- Configure um Datasource `prometheus no localhost 9090`
- Alerta configurado: **CPU acima de 80% por 1 minuto**

---

## Banco de dados

O container do PostgreSQL:

- Usa volume persistente nomeado: `pgdata`
- Executa o script `script.sql` na inicialização
- Está na rede privada com o backend

---

## Tecnologias Utilizadas

- Docker
- Terraform (provider `kreuzwerker/docker`)
- Node.js (versão 18)
- PostgreSQL 15.8
- NGINX
- Prometheus
- Grafana
- cAdvisor

---

## Observações

- O backend expõe métricas via `prom-client`
- Todos os serviços são reiniciados automaticamente (`restart = always`)
- Os contêineres estão organizados em duas redes:
  - `backend_network` (backend, db, prometheus, grafana, cadvisor)
  - `frontend_network` (frontend + backend)

---

## Comandos Úteis

```bash
# Ver containers
docker ps

# Ver logs de um container
docker logs backend_cubos

# Remover tudo
terraform destroy -auto-approve
```

---

## Checklist final do desafio

- [x] Backend conecta ao banco via variáveis
- [x] Frontend se comunica com backend (proxy_pass)
- [x] Banco com volume persistente
- [x] Provisionamento via Terraform
- [x] Prometheus e Grafana funcionando
- [x] Métricas expostas e coletadas
- [x] Dashboard Grafana com alerta
- [x] Tudo documentado neste README

---

## Contato

Desenvolvido por Dennis Augusto Gusmão  
Email: dennis.gusmao@outlook.com  
LinkedIn: https://www.linkedin.com/in/dennis-gusm%C3%A3o-16150b119/


## Alterações Realizadas nos Arquivos Originais do Desafio

Durante o desenvolvimento da solução, foram realizadas alterações e melhorias nos arquivos fornecidos pela equipe do desafio. Abaixo estão listadas as modificações com suas respectivas justificativas:

### `backend/index.js`
**Original:**  
- Não fazia tratamento de erro adequado para conexões falhas.  
- Ausência de variáveis de ambiente nomeadas (`user`, `pass`, `host`, etc. não definidos).  
- Estrutura de conexão com o banco estava diretamente dentro da requisição.  
- Não expunha métricas para Prometheus.  

**Modificado:**  
- Conexão com o banco foi isolada e retardada (`setTimeout`) para garantir que o banco esteja de pé ao iniciar.  
- Inclusão de variáveis de ambiente (`DB_USER`, `DB_PASS`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `PORT`).  
- Adicionado suporte a Prometheus via biblioteca `prom-client` com rota `/metrics`.  
- Log detalhado e tratamento robusto de erros com feedback visual (emojis).  
- Adicionada verificação mais segura do resultado da query.  
- Retornando `404` em caso de rota não encontrada.

**Motivo:**  
Melhorar a resiliência da aplicação, seguir boas práticas DevOps (observabilidade com métricas), e preparar o backend para integração com Prometheus/Grafana.

---

### `backend/package.json`
**Original:**  
- Apenas a dependência `pg` estava presente.  

**Modificado:**  
- Adicionada dependência `prom-client` para exposição de métricas no backend.  
- Incluído script `start` para padronizar execução.

**Motivo:**  
Permitir que o Prometheus colete métricas do backend e seguir estrutura esperada em ambientes Node.js.

---

### `frontend/index.html`
**Original:**  
- A função `fetchAPI` utilizava `mode: 'no-cors'`, o que impedia o tratamento da resposta JSON.  
- Nenhum tratamento de erro era feito em caso de falha de conexão.  
- Botão nunca era desativado em caso de erro.

**Modificado:**  
- Removido `mode: 'no-cors'` para permitir leitura da resposta.  
- Adicionado tratamento de erro com mensagens amigáveis.  
- Atualização de mensagens visuais para indicar sucesso/erro com ícones (`✅` e `❌`).  

**Motivo:**  
Melhorar a usabilidade e experiência visual do usuário, além de permitir debug e observação mais efetiva.

---

### `sql/`
**Original:**  
- Apenas `script.sql` existia, com a criação da tabela `users` e inserção do admin.

**Modificado:**  
- Adicionados arquivos auxiliares como `generate_sql.sh`, `.env` e `script.sql.tpl`.  
- Uso de template para gerar SQL dinâmico em tempo de execução com dados sensíveis movidos para variáveis de ambiente.  

**Motivo:**  
Aumentar a segurança (evitar hardcoded de dados sensíveis) e garantir flexibilidade para execução dinâmica no provisionamento.

---

Essas modificações foram fundamentais para garantir um ambiente observável, escalável, seguro e alinhado às boas práticas modernas de infraestrutura como código.
