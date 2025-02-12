const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

exports.sendBroadcastMessage = functions.https.onRequest(async (request, response) => {
  // Enable CORS
  response.set('Access-Control-Allow-Origin', '*');
  
  if (request.method === 'OPTIONS') {
    // Send response to OPTIONS requests
    response.set('Access-Control-Allow-Methods', 'POST');
    response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.status(204).send('');
    return;
  }

  try {
    // Validate request method
    if (request.method !== 'POST') {
      throw new Error('Only POST requests are accepted');
    }

    // Validate request body
    const { tokens, notification, data } = request.body;
    
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new Error('No valid tokens provided');
    }

    if (!notification || !notification.title || !notification.body) {
      throw new Error('Invalid notification format');
    }

    // Prepare the message
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data || {},
      tokens: tokens, // Can send up to 500 tokens at once
    };

    // Send the message
    const batchResponse = await admin.messaging().sendMulticast(message);

    // Prepare detailed response
    const responseData = {
      success: batchResponse.successCount,
      failure: batchResponse.failureCount,
      errors: [],
    };

    // Collect any errors
    if (batchResponse.failureCount > 0) {
      batchResponse.responses.forEach((resp, idx) => {
        if (!resp.success) {
          responseData.errors.push({
            token: tokens[idx],
            error: resp.error.message,
          });
        }
      });
    }

    // Send success response
    response.status(200).json(responseData);

  } catch (error) {
    console.error('Error sending broadcast:', error);
    response.status(500).json({
      error: error.message || 'Internal server error',
    });
  }
});