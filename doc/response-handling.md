# Response Handling

nvim-http-client provides rich features for handling HTTP responses, including the ability to view, save, and process responses with custom handlers.

## Response Window

Responses are displayed in a dedicated split window with the following features:

- Each response creates a new tab with timestamp
- Latest 10 responses are preserved
- Automatic formatting for JSON and XML responses
- Syntax highlighting for response bodies
- Timing metrics when profiling is enabled

### Navigation

You can navigate between responses using:

- `H` - Previous response
- `L` - Next response
- `q` or `<Esc>` - Close response window

## Response Handlers

Response handlers allow you to execute custom code after receiving a response. This is useful for extracting data from responses and using it in subsequent requests.

### Syntax

Response handlers are defined using the following syntax:

```http
### Your HTTP Request
GET {{host}}/api/endpoint

> {%
// Your JavaScript code here
%}
```

The code between `> {%` and `%}` is executed after the response is received.

### Available Objects

Within a response handler, you have access to:

- `response` - The HTTP response object
  - `response.body` - The response body (parsed as JSON if possible)
  - `response.headers` - Response headers
  - `response.status` - HTTP status code

- `client` - The HTTP client object
  - `client.global.set(key, value)` - Set a global variable for use in subsequent requests

### Example: Extracting an Authentication Token

```http
### Login
POST {{host}}/api/login
Content-Type: application/json

{
    "username": "{{username}}",
    "password": "{{password}}"
}

> {%
// Extract the token from the response
const token = response.body.token;

// Store it as a global variable
client.global.set("auth_token", token);

// Log information (appears in response window)
console.log("Token extracted and stored as auth_token");
%}

### Get Protected Resource
GET {{host}}/api/protected
Authorization: Bearer {{auth_token}}
```

### Example: Processing Data

```http
### Get Users
GET {{host}}/api/users

> {%
// Count the number of users
const userCount = response.body.length;
client.global.set("userCount", userCount);

// Find a specific user
const adminUser = response.body.find(user => user.role === 'admin');
if (adminUser) {
    client.global.set("adminId", adminUser.id);
}
%}

### Get Admin Details
GET {{host}}/api/users/{{adminId}}
```

## Saving Responses

You can save the current response body to a file using:

- Command: `:HttpSaveResponse`
- Default keybinding: `<leader>hs` (if enabled)

When saving a response:
1. You'll be prompted for a filename
2. The response body will be formatted (if it's JSON or XML)
3. The formatted content will be saved to the specified file 