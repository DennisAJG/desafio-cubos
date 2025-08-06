import http from 'http';
import PG from 'pg';

const port = Number(process.env.PORT) || 3000;

const user = process.env.DB_USER;
const pass = process.env.DB_PASS;
const host = process.env.DB_HOST;
const db_port = process.env.DB_PORT;
const db_name = process.env.DB_NAME;

const client = new PG.Client(
  `postgres://${user}:${pass}@${host}:${db_port}/${db_name}`
);

let successfulConnection = false;

setTimeout(async () => {
  try {
    await client.connect();
    successfulConnection = true;
    console.log("✅ Conectado ao banco de dados com sucesso.");
  } catch (err) {
    console.error("❌ Erro ao conectar no banco de dados:", err.stack);
  }

  http.createServer(async (req, res) => {
    console.log(`Request: ${req.url}`);

    if (req.url === "/api") {
      res.setHeader("Content-Type", "application/json");
      res.writeHead(200);

      let result;
      let isAdmin = false;

      if (successfulConnection) {
        try {
          const queryResult = await client.query("SELECT * FROM users");
          result = queryResult.rows[0];
          console.log("👤 Resultado do banco:", result);
          isAdmin = result?.role === "admin";
        } catch (error) {
          console.error("❌ Erro ao consultar usuários:", error);
        }
      }

      const data = {
        database: successfulConnection,
        userAdmin: isAdmin
      };

      res.end(JSON.stringify(data));
    } else {
      res.writeHead(404);
      res.end("Not Found");
    }

  }).listen(port, () => {
    console.log(`🚀 Servidor escutando na porta ${port}`);
  });
}, 5000);
