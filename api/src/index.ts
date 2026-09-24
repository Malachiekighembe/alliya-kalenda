import { createApp } from "./app";
import { config } from "./config";

const app = createApp();

app.listen(config.PORT, () => {
  console.log(
    `Alliya Kalenda API — ${config.NODE_ENV} sur http://localhost:${config.PORT}`,
  );
});
