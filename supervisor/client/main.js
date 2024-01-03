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
      logResponse("Login response", data);
      localStorage.setItem("jwt", data.access_token);
      updateResponse("Login successful");
    })
    .catch((error) => {
      logResponse("Login error", error);
      updateResponse("Login failed");
    });
}

function getClusterInfo() {
  const token = localStorage.getItem("jwt");
  fetch("/cluster-info", {
    headers: { Authorization: `Bearer ${token}` },
  })
    .then((response) => response.json())
    .then((data) => {
      logResponse("Cluster info response", data);
      updateResponse(JSON.stringify(data, null, 2));
    })
    .catch((error) => {
      logResponse("Cluster info error", error);
      updateResponse("Failed to get cluster info");
    });
}

function checkHealth() {
  fetch("/health")
    .then((response) => response.json())
    .then((data) => {
      logResponse("Health check response", data);
      updateResponse(JSON.stringify(data, null, 2));
    })
    .catch((error) => {
      logResponse("Health check error", error);
      updateResponse("Server health check failed");
    });
}

function controlDoodle(action) {
  const token = localStorage.getItem("jwt");
  fetch("/doodle-control", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ action }),
  })
    .then((response) => response.json())
    .then((data) => {
      logResponse("Doodle control response", data);
      updateResponse(
        `Doodle ${action} response: ` + JSON.stringify(data, null, 2),
      );
    })
    .catch((error) => {
      logResponse("Doodle control error", error);
      updateResponse(`Failed to ${action} Doodle`);
    });
}

function updateResponse(message) {
  document.getElementById("response").textContent = message;
}

function logResponse(title, data) {
  console.log(title + ": " + JSON.stringify(data, null, 2));
}
