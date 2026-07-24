const OWNER = "eadon24";
const REPO = "taxes";
const BRANCH = "main";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Método no permitido" });
  }

  try {
    const { contenido } = req.body;

    if (!contenido) {
      return res.status(400).json({
        error: "No se recibió el contenido",
      });
    }

    const token = process.env.GITHUB_TOKEN;

    const ruta = "web/tasas.json";

    const githubUrl = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${ruta}`;

    // Obtener SHA actual
    const get = await fetch(githubUrl, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
      },
    });

    if (!get.ok) {
      const error = await get.text();
      return res.status(500).json({
        paso: "GET",
        error,
      });
    }

    const actual = await get.json();

    // Actualizar archivo
    const put = await fetch(githubUrl, {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Actualización automática de tasas",
        content: Buffer.from(contenido).toString("base64"),
        sha: actual.sha,
        branch: BRANCH,
      }),
    });

    const resultado = await put.json();

    if (!put.ok) {
      return res.status(500).json({
        paso: "PUT",
        resultado,
      });
    }

    return res.status(200).json({
      ok: true,
      commit: resultado.commit.html_url,
    });
  } catch (e) {
    return res.status(500).json({
      error: e.toString(),
    });
  }
}