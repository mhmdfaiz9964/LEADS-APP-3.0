# WhatsApp Messaging Feature Documentation (WasenderApi)

This document outlines the implementation and usage of the WhatsApp messaging feature integrated with WasenderApi in the Leads App.

## 🚀 Overview

The feature allows administrators to send WhatsApp messages (text and images) to customers and leads through the **WasenderApi** platform. It provides a complete history of sent messages, detailed analytics for each message, and bulk sending capabilities.

## 🛠️ Components

### 1. WhatsAppService (`lib/services/whatsapp_service.dart`)
Handles communication with the WasenderApi.
- **`sendMessage`**: Sends a text or image message to a specific number.
- **`getHistory`**: Retrieves the sent message history from Firestore.
- **`getMessageDetails`**: Gets detailed info for a specific history entry.

### 2. WhatsAppMessage Model (`lib/models/whatsapp_message_model.dart`)
Defines the structure for message tracking:
- `to`: Recipient phone number.
- `text`: Message content.
- `imageUrl`: (Optional) URL of the attached image.
- `status`: 'sent' or 'failed'.
- `timestamp`: When the message was sent.
- `senderEmail`: Who initiated the message.

### 3. Screens
- **`WhatsAppHistoryScreen`**: A premium dashboard showing all sent messages with search and filter capabilities.
- **`WhatsAppDetailsScreen`**: Shows status, content, media, and metadata for a specific message. Includes a "Resend" option.
- **`SendWhatsAppBulkScreen`**: Allows admins to select multiple customers and send a unified message/image.
- **`SendWhatsAppMessageScreen`**: Integrated into Customer/Lead details for direct messaging.

## 🔑 Configuration

The WhatsApp API key is managed via **Firestore** for better security and dynamic updates.

1.  Open your **Firebase Console**.
2.  Go to **Cloud Firestore**.
3.  Create a collection named `settings`.
4.  Create a document named `whatsapp_api`.
5.  Add a field:
    *   **Field Name**: `apiKey`
    *   **Type**: `string`
    *   **Value**: Your actual Wasender API key.

## 📈 Usage Flow

1. **Admin Sidebar**: Access "WhatsApp History" or "Bulk WhatsApp".
2. **Customer/Lead Details**: Click the "WhatsApp" button in the header (Admins only) to send a direct message.
3. **Bulk Sending**:
   - Go to "Bulk WhatsApp".
   - Select recipients from the customer list.
   - Enter message and optional image URL.
   - Click "Send".

## 🎨 Design Aesthetics
- **Typography**: Uses `GoogleFonts.outfit` for a modern, sleek look.
- **Colors**: Premium Blue and Slate palettes with subtle gradients and shadows.
- **Feedback**: Real-time progress indicators and success/error dialogs for better UX.

---
© 2026 Leads App Team
