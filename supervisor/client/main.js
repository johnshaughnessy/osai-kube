function request(url, options = {}) {
  return fetch(url, options).then((response) => response.json());
}

function login() {
  const username = document.getElementById("username").value;
  const password = document.getElementById("password").value;

  request("/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  })
    .then((data) => {
      localStorage.setItem("jwt", data.access_token);
      document.getElementById("response").textContent = "Login successful";
    })
    .catch(() => {
      document.getElementById("response").textContent = "Login failed";
    });
}

function getClusterInfo() {
  const token = localStorage.getItem("jwt");
  request("/cluster-info", {
    headers: { Authorization: `Bearer ${token}` },
  })
    .then((data) => {
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
  request("/health")
    .then((data) => {
      document.getElementById("response").textContent = data;
    })
    .catch(() => {
      document.getElementById("response").textContent =
        "Server health check failed";
    });
}
