const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const path = require('path');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:"],
    },
  },
}));

// Body parser middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Session middleware
app.use(session({
  secret: 'banking-app-secret-key-change-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 1800000 // 30 minutes
  }
}));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Initialize Key Vault client
let secretClient;
let validCustomerId = '5439090';
let validPassword = 'Passw0rd!!';

async function initializeKeyVault() {
  try {
    const keyVaultUrl = process.env.KEY_VAULT_URL;
    if (keyVaultUrl) {
      console.log('Initializing Key Vault connection...');
      const credential = new DefaultAzureCredential();
      secretClient = new SecretClient(keyVaultUrl, credential);
      
      // Retrieve secrets from Key Vault
      const customerIdSecret = await secretClient.getSecret('customer-id');
      const passwordSecret = await secretClient.getSecret('customer-password');
      
      validCustomerId = customerIdSecret.value;
      validPassword = passwordSecret.value;
      
      console.log('✓ Successfully connected to Key Vault');
    } else {
      console.log('⚠ KEY_VAULT_URL not set, using default credentials');
    }
  } catch (error) {
    console.error('⚠ Key Vault initialization failed, using default credentials:', error.message);
  }
}

// Authentication middleware
function requireAuth(req, res, next) {
  if (req.session && req.session.authenticated) {
    return next();
  }
  res.redirect('/');
}

// Routes
app.get('/', (req, res) => {
  if (req.session.authenticated) {
    return res.redirect('/home');
  }
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.post('/login', (req, res) => {
  const { customerId, password } = req.body;
  
  // Log login attempt (for SIEM)
  console.log(`Login attempt for customer ID: ${customerId}`);
  
  if (customerId === validCustomerId && password === validPassword) {
    req.session.authenticated = true;
    req.session.customerId = customerId;
    console.log(`✓ Successful login for customer ID: ${customerId}`);
    res.json({ success: true });
  } else {
    console.log(`✗ Failed login attempt for customer ID: ${customerId}`);
    res.json({ success: false, message: 'Invalid credentials' });
  }
});

app.get('/home', requireAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'home.html'));
});

app.get('/api/customer-data', requireAuth, (req, res) => {
  res.json({
    customerId: req.session.customerId,
    name: 'John Doe',
    accountType: 'Premium Savings',
    balance: '$125,430.50',
    lastLogin: new Date().toLocaleString()
  });
});

app.post('/logout', (req, res) => {
  req.session.destroy();
  res.json({ success: true });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
async function startServer() {
  await initializeKeyVault();
  
  app.listen(PORT, () => {
    console.log('=================================================');
    console.log(`🏦 Secure Banking Application`);
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🔒 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔐 Key Vault: ${process.env.KEY_VAULT_URL || 'Not configured'}`);
    console.log('=================================================');
  });
}

startServer();
