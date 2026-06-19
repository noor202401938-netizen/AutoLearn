# Payment Setup Guide

## Overview

This app uses **Stripe** for payment processing. To make payments functional, you need to:

1. Set up a Stripe account
2. Get your API keys
3. Configure the app with your keys
4. Set up a backend server (recommended) or use test mode

---

## Step 1: Create Stripe Account

1. Go to [https://stripe.com](https://stripe.com)
2. Sign up for a free account
3. Complete the account setup
4. Switch to **Test Mode** for development

---

## Step 2: Get Your API Keys

1. Go to **Developers** → **API keys** in Stripe Dashboard
2. You'll see two keys:
   - **Publishable key** (starts with `pk_test_...` for test mode)
   - **Secret key** (starts with `sk_test_...` for test mode)

⚠️ **IMPORTANT**: Never expose your secret key in client-side code!

---

## Step 3: Configure the App

### Option A: Direct Configuration (Test Mode Only)

**File**: `lib/backend/payment_gateway_service.dart`

```dart
// Replace these with your actual keys
static const String _stripePublishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
static const String _stripeSecretKey = 'sk_test_YOUR_SECRET_KEY';
```

**File**: `lib/main.dart`

Make sure Stripe is initialized:

```dart
// In main() function, after Firebase initialization
await Stripe.instance.applySettings();
Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
```

### Option B: Environment Variables (Recommended)

1. Create a `.env` file in the project root:
```
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
STRIPE_SECRET_KEY=sk_test_YOUR_KEY
```

2. Add `flutter_dotenv` package to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

3. Load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  // ... rest of initialization
}
```

4. Use in code:
```dart
static const String _stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
```

---

## Step 4: Backend Server Setup (Production)

For production, you **MUST** set up a backend server to handle payment intents securely.

### Why?
- Secret keys must never be exposed in client apps
- Payment processing requires server-side validation
- Better security and compliance

### Backend Implementation Example (Node.js/Express)

```javascript
// server.js
const express = require('express');
const stripe = require('stripe')('sk_live_YOUR_SECRET_KEY');

const app = express();
app.use(express.json());

// Create payment intent endpoint
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency } = req.body;
  
  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency || 'usd',
    });
    
    res.json({
      id: paymentIntent.id,
      client_secret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));
```

### Update Flutter Code

**File**: `lib/backend/payment_gateway_service.dart`

```dart
Future<Map<String, dynamic>> createPaymentIntent({
  required int amountCents,
  String currency = 'USD',
}) async {
  try {
    // Call your backend API
    final response = await http.post(
      Uri.parse('https://your-backend.com/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amountCents,
        'currency': currency.toLowerCase(),
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create payment intent');
    }
  } catch (e) {
    throw Exception('Payment initialization failed: $e');
  }
}
```

---

## Step 5: Test Payments

### Test Card Numbers (Stripe Test Mode)

Use these test cards in the payment screen:

| Card Number | Description |
|------------|-------------|
| `4242 4242 4242 4242` | Visa - Success |
| `4000 0000 0000 0002` | Card declined |
| `4000 0000 0000 9995` | Insufficient funds |

**Expiry**: Any future date (e.g., `12/25`)  
**CVC**: Any 3 digits (e.g., `123`)  
**ZIP**: Any 5 digits (e.g., `12345`)

---

## Step 6: Payment Flow

The current payment flow:

1. **User clicks "Enroll"** on a course
2. **Check if user has paid** (`PaymentManager.hasUserPaid()`)
3. **If not paid**, show payment screen
4. **User enters card details**
5. **Create payment intent** (backend or mock)
6. **Process payment** with Stripe
7. **Mark user as paid** in Firestore
8. **Enroll user** in course

---

## Current Implementation Status

### ✅ Implemented:
- Payment screen UI
- Payment manager logic
- Payment repository (Firestore)
- Stripe integration structure

### ⚠️ Needs Configuration:
- Stripe API keys
- Backend server (for production)
- Payment intent creation endpoint

### 📝 Files to Update:

1. **`lib/backend/payment_gateway_service.dart`**
   - Add your Stripe publishable key
   - Set up backend API URL (for production)

2. **`lib/main.dart`**
   - Initialize Stripe with publishable key

3. **`lib/business_logic/payment_manager.dart`**
   - Already configured, no changes needed

4. **`lib/repository/payment_repository.dart`**
   - Already configured, no changes needed

---

## Testing Checklist

- [ ] Stripe account created
- [ ] API keys obtained
- [ ] Keys configured in app
- [ ] Test payment with test card
- [ ] Payment success flow works
- [ ] User marked as paid in Firestore
- [ ] Enrollment works after payment
- [ ] Error handling works (declined cards)

---

## Security Best Practices

1. **Never commit API keys to Git**
   - Use `.gitignore` for `.env` files
   - Use environment variables
   - Use secure key storage services

2. **Use backend for production**
   - Never use secret keys in client code
   - Validate payments server-side
   - Implement webhook handlers

3. **Enable Stripe security features**
   - Enable 3D Secure (SCA compliance)
   - Set up webhooks for payment events
   - Monitor for fraudulent activity

---

## Troubleshooting

### "Payment initialization failed"
- Check API keys are correct
- Verify network connection
- Check Stripe dashboard for errors

### "Card declined"
- Use test card numbers in test mode
- Check card details are correct
- Verify Stripe account is active

### "Payment method not found"
- Ensure payment method is created before confirmation
- Check payment intent ID is valid
- Verify payment intent status

---

## Additional Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Flutter Stripe Package](https://pub.dev/packages/flutter_stripe)
- [Stripe Test Cards](https://stripe.com/docs/testing)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

---

## Support

For payment-related issues:
1. Check Stripe Dashboard → Logs
2. Review error messages in app
3. Test with Stripe test cards
4. Verify backend endpoints (if using)

---

## Next Steps

1. **Development**: Use test mode with test cards
2. **Staging**: Test with real cards (test mode)
3. **Production**: 
   - Set up backend server
   - Switch to live mode
   - Configure webhooks
   - Enable security features

---

**Note**: The current implementation includes a mock payment intent creation. For production, you **must** replace this with a backend API call.

