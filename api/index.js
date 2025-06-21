// api/index.js
const express = require('express');
const stripe = require('stripe')(process.env.sk_test_51Rc54mCalxIdZZebsPmY4fehZOqlg2cfK8RBFGG7kM9Gr2oMo8K6wDJRhRty0tewh2T6Un0QDv7VlJaZTelVPzin00j6GvLATF); // Initialize Stripe with secret key from environment variables
const cors = require('cors');

const app = express();

// Use CORS middleware to allow requests from your Flutter app (origin: any for dev)
app.use(cors({ origin: 'https://food-delivery-app-five-navy.vercel.app/' })); // IMPORTANT: For production, change '*' to your Flutter app's domain
app.use(express.json()); // Enable JSON body parsing

// Define a POST endpoint for creating a Payment Intent
app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body; // Amount comes from the Flutter app

  if (!amount || typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ error: 'Invalid amount provided' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Stripe expects amount in cents
      currency: 'usd', // Or 'idr' for Indonesian Rupiah (Stripe supports IDR)
      payment_method_types: ['card'], // We'll accept card payments
    });

    // Send back the client secret and paymentIntentId to the Flutter app
    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (e) {
    console.error('Error creating Payment Intent:', e);
    res.status(500).json({ error: e.message });
  }
});

// You can also define a simple GET endpoint for testing if the server is running
app.get('/', (req, res) => {
  res.send('Stripe Payment Intent API is running!');
});

// Export the app for Vercel
module.exports = app;