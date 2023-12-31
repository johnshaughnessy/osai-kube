function login() {
  const username = document.getElementById("username").value;
  const password = document.getElementById("password").value;

  fetch("/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  })
    .then((response) => response.json())
    .then((data) => {
      console.log(JSON.stringify(data, null, 2));
      localStorage.setItem("jwt", data.access_token);
      document.getElementById("response").textContent = "Login successful";
    })
    .catch(() => {
      document.getElementById("response").textContent = "Login failed";
    });
}

function getClusterInfo() {
  const token = localStorage.getItem("jwt");
  fetch("/cluster-info", {
    headers: { Authorization: `Bearer ${token}` },
  })
    .then((response) => response.json())
    .then((data) => {
      console.log(JSON.stringify(data, null, 2));
      document.getElementById("response").textContent = JSON.stringify(
        data,
        null,
        2,
      );
    })
    .catch(() => {
      document.getElementById("response").textContent =
        "Failed to get cluster info";
    });
}

function checkHealth() {
  fetch("/health")
    .then((response) => response.json())
    .then((data) => {
      console.log(JSON.stringify(data, null, 2));
      document.getElementById("response").textContent = data;
    })
    .catch((e) => {
      console.error(e);
      document.getElementById("response").textContent =
        "Server health check failed";
    });
}
