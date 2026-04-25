const attempts = 3;

for (let i = 1; i <= attempts; i += 1) {
  const response = await fetch("http://127.0.0.1:8100/auth/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      email: "admin1@example.com",
      password: "wrongpass",
      type: "admin"
    })
  });

  const body = await response.text();
  console.log(`attempt:${i} status:${response.status} body:${body}`);
}
