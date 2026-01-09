<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$servername = "srv1816.hstgr.io";
$username = "u651590170_apper";
$password = "Woyager120.";
$dbname = "u651590170_apper";

// Bağlantı oluştur
$conn = new mysqli($servername, $username, $password, $dbname);

// Bağlantı kontrolü
if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

// Gelen veriyi al
$data = json_decode(file_get_contents("php://input"), true);
$action = isset($_GET['action']) ? $_GET['action'] : '';

switch ($action) {
    case 'get_users':
        $sql = "SELECT * FROM users";
        $result = $conn->query($sql);
        $rows = [];
        while($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        echo json_encode($rows);
        break;

    case 'get_user':
        $email = $conn->real_escape_string($_GET['email']);
        $sql = "SELECT * FROM users WHERE email = '$email'";
        $result = $conn->query($sql);
        if ($result->num_rows > 0) {
            echo json_encode($result->fetch_assoc());
        } else {
            echo json_encode(null);
        }
        break;
        
    case 'get_password': // Güvenlik için önerilmez ama mevcut yapıyı koruyoruz
        $email = $conn->real_escape_string($_GET['email']);
        $sql = "SELECT password FROM users WHERE email = '$email'";
        $result = $conn->query($sql);
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo json_encode($row['password']); // Doğrudan string döndürürsek JSON parse hatası olabilir, o yüzden encode ediyoruz.
        } else {
            echo json_encode(null);
        }
        break;

    case 'create_user':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("INSERT INTO users (id, name, email, password, role, status, registration_date, cart, portfolio, investment_settings) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssssssssss", $data['id'], $data['name'], $data['email'], $data['password'], $data['role'], $data['status'], $data['registration_date'], $data['cart'], $data['portfolio'], $data['investment_settings']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    case 'update_user':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("UPDATE users SET name=?, cart=?, portfolio=?, investment_settings=? WHERE id=?");
        $stmt->bind_param("sssss", $data['name'], $data['cart'], $data['portfolio'], $data['investment_settings'], $data['id']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    case 'get_products':
        $sql = "SELECT * FROM products";
        $result = $conn->query($sql);
        $rows = [];
        while($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        echo json_encode($rows);
        break;

    case 'create_product':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("INSERT INTO products (id, name, price, image_url, brand, category, stock, colors) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssisssis", $data['id'], $data['name'], $data['price'], $data['image_url'], $data['brand'], $data['category'], $data['stock'], $data['colors']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;
        
    case 'update_product':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("UPDATE products SET name=?, price=?, image_url=?, brand=?, category=?, stock=?, colors=? WHERE id=?");
        $stmt->bind_param("sisssiss", $data['name'], $data['price'], $data['image_url'], $data['brand'], $data['category'], $data['stock'], $data['colors'], $data['id']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    case 'delete_product':
        $id = $conn->real_escape_string($_GET['id']);
        $sql = "DELETE FROM products WHERE id='$id'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $conn->error]);
        }
        break;

    case 'get_funds':
        $sql = "SELECT * FROM funds";
        $result = $conn->query($sql);
        $rows = [];
        while($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        echo json_encode($rows);
        break;
        
    case 'create_fund':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("INSERT INTO funds (code, name, price) VALUES (?, ?, ?)");
        $stmt->bind_param("ssd", $data['code'], $data['name'], $data['price']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    case 'update_fund':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("UPDATE funds SET name=?, price=? WHERE code=?");
        $stmt->bind_param("sds", $data['name'], $data['price'], $data['code']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    case 'delete_fund':
        $code = $conn->real_escape_string($_GET['code']);
        $sql = "DELETE FROM funds WHERE code='$code'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $conn->error]);
        }
        break;

    case 'get_transactions':
        $user_id = $conn->real_escape_string($_GET['user_id']);
        $sql = "SELECT * FROM transactions WHERE user_id = '$user_id' ORDER BY date DESC";
        $result = $conn->query($sql);
        $rows = [];
        while($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        echo json_encode($rows);
        break;

    case 'add_transaction':
        if (!$data) { echo json_encode(["error" => "No data"]); break; }
        $stmt = $conn->prepare("INSERT INTO transactions (user_id, type, description, amount, date) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sssis", $data['user_id'], $data['type'], $data['description'], $data['amount'], $data['date']);
        if ($stmt->execute()) {
            echo json_encode(["success" => true]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        break;

    default:
        echo json_encode(["message" => "Invalid action"]);
}

$conn->close();
?>
