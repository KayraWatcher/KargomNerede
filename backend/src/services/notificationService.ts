// Notification Service - Handles FCM notifications and in-app notifications

import admin from 'firebase-admin';

export interface Notification {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
  shipmentId?: string;
  data?: Record<string, any>;
  read: boolean;
  createdAt: string;
}

export type NotificationType = 
  | 'new_movement'
  | 'arrived_at_facility'
  | 'out_for_delivery'
  | 'delivered'
  | 'exception'
  | 'delay'
  | 'returned';

export interface NotificationPreferences {
  userId: string;
  enabled: boolean;
  newMovement: boolean;
  arrivedAtFacility: boolean;
  outForDelivery: boolean;
  delivered: boolean;
  exception: boolean;
  delay: boolean;
  wifiOnly: boolean;
  updatedAt: string;
}

export interface FCMToken {
  id: string;
  userId: string;
  token: string;
  platform: 'android' | 'ios' | 'web';
  createdAt: string;
}

class NotificationService {
  private notifications: Map<string, Notification[]> = new Map();
  private preferences: Map<string, NotificationPreferences> = new Map();
  private fcmTokens: Map<string, FCMToken[]> = new Map();
  private messaging: admin.messaging.Messaging | null = null;

  constructor() {
    this.initializeFirebase();
    this.initializeMockData();
  }

  private initializeFirebase() {
    try {
      if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          }),
        });
        this.messaging = admin.messaging();
        console.log('Firebase Admin initialized');
      }
    } catch (error) {
      console.warn('Firebase Admin not initialized:', error);
    }
  }

  private initializeMockData() {
    const mockPrefs: NotificationPreferences = {
      userId: 'user_1',
      enabled: true,
      newMovement: true,
      arrivedAtFacility: true,
      outForDelivery: true,
      delivered: true,
      exception: true,
      delay: true,
      wifiOnly: false,
      updatedAt: new Date().toISOString(),
    };
    this.preferences.set('user_1', mockPrefs);

    const mockNotifications: Notification[] = [
      {
        id: 'notif_1',
        userId: 'user_1',
        title: 'Kargonuz Dağıtıma Çıktı',
        body: 'Yurtiçi Kargo - 1234567890123 bugün teslim edilecek.',
        type: 'out_for_delivery',
        shipmentId: 'shipment_1',
        read: false,
        createdAt: new Date(Date.now() - 1800000).toISOString(),
      },
      {
        id: 'notif_2',
        userId: 'user_1',
        title: 'Teslim Edildi',
        body: 'MNG Kargo - 9876543210 başarıyla teslim edildi.',
        type: 'delivered',
        shipmentId: 'shipment_2',
        read: true,
        createdAt: new Date(Date.now() - 7200000).toISOString(),
      },
    ];
    this.notifications.set('user_1', mockNotifications);
  }

  // In-app notifications
  async getUserNotifications(
    userId: string,
    options: { unreadOnly: boolean; page: number; limit: number }
  ): Promise<{ notifications: Notification[]; total: number; unreadCount: number }> {
    let userNotifications = this.notifications.get(userId) || [];
    
    if (options.unreadOnly) {
      userNotifications = userNotifications.filter(n => !n.read);
    }

    const total = userNotifications.length;
    const unreadCount = userNotifications.filter(n => !n.read).length;
    
    // Sort by createdAt descending
    userNotifications.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    
    const start = (options.page - 1) * options.limit;
    const notifications = userNotifications.slice(start, start + options.limit);

    return { notifications, total, unreadCount };
  }

  async markAsRead(notificationId: string, userId: string): Promise<Notification | null> {
    const userNotifications = this.notifications.get(userId) || [];
    const notification = userNotifications.find(n => n.id === notificationId);
    
    if (notification) {
      notification.read = true;
      this.notifications.set(userId, userNotifications);
      return notification;
    }
    return null;
  }

  async markAllAsRead(userId: string): Promise<void> {
    const userNotifications = this.notifications.get(userId) || [];
    userNotifications.forEach(n => n.read = true);
    this.notifications.set(userId, userNotifications);
  }

  async deleteNotification(notificationId: string, userId: string): Promise<boolean> {
    const userNotifications = this.notifications.get(userId) || [];
    const filtered = userNotifications.filter(n => n.id !== notificationId);
    this.notifications.set(userId, filtered);
    return filtered.length !== userNotifications.length;
  }

  // Preferences
  async getPreferences(userId: string): Promise<NotificationPreferences> {
    let prefs = this.preferences.get(userId);
    if (!prefs) {
      prefs = this.getDefaultPreferences(userId);
      this.preferences.set(userId, prefs);
    }
    return prefs;
  }

  async updatePreferences(userId: string, updates: Partial<NotificationPreferences>): Promise<NotificationPreferences> {
    const prefs = await this.getPreferences(userId);
    const updated = { ...prefs, ...updates, updatedAt: new Date().toISOString() };
    this.preferences.set(userId, updated);
    return updated;
  }

  private getDefaultPreferences(userId: string): NotificationPreferences {
    return {
      userId,
      enabled: true,
      newMovement: true,
      arrivedAtFacility: true,
      outForDelivery: true,
      delivered: true,
      exception: true,
      delay: true,
      wifiOnly: false,
      updatedAt: new Date().toISOString(),
    };
  }

  // FCM Tokens
  async registerFCMToken(userId: string, token: string, platform: 'android' | 'ios' | 'web'): Promise<void> {
    const tokens = this.fcmTokens.get(userId) || [];
    
    // Remove existing token if present
    const filtered = tokens.filter(t => t.token !== token);
    
    const fcmToken: FCMToken = {
      id: `token_${Date.now()}`,
      userId,
      token,
      platform,
      createdAt: new Date().toISOString(),
    };
    
    filtered.push(fcmToken);
    this.fcmTokens.set(userId, filtered);
  }

  async unregisterFCMToken(userId: string, token: string): Promise<void> {
    const tokens = this.fcmTokens.get(userId) || [];
    const filtered = tokens.filter(t => t.token !== token);
    this.fcmTokens.set(userId, filtered);
  }

  async getUserTokens(userId: string): Promise<string[]> {
    const tokens = this.fcmTokens.get(userId) || [];
    return tokens.map(t => t.token);
  }

  // Send notification
  async sendNotification(notification: Omit<Notification, 'id' | 'createdAt' | 'read'>): Promise<void> {
    const fullNotification: Notification = {
      ...notification,
      id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      read: false,
      createdAt: new Date().toISOString(),
    };

    // Store in-app notification
    const userNotifications = this.notifications.get(notification.userId) || [];
    userNotifications.unshift(fullNotification);
    // Keep only last 100 notifications
    if (userNotifications.length > 100) {
      userNotifications.splice(100);
    }
    this.notifications.set(notification.userId, userNotifications);

    // Send FCM if enabled
    if (this.messaging && await this.shouldSendFCM(notification.userId, notification.type)) {
      await this.sendFCM(notification.userId, fullNotification);
    }
  }

  private async shouldSendFCM(userId: string, type: NotificationType): Promise<boolean> {
    const prefs = await this.getPreferences(userId);
    if (!prefs.enabled) return false;

    switch (type) {
      case 'new_movement': return prefs.newMovement;
      case 'arrived_at_facility': return prefs.arrivedAtFacility;
      case 'out_for_delivery': return prefs.outForDelivery;
      case 'delivered': return prefs.delivered;
      case 'exception': return prefs.exception;
      case 'delay': return prefs.delay;
      case 'returned': return prefs.exception;
      default: return true;
    }
  }

  private async sendFCM(userId: string, notification: Notification): Promise<void> {
    if (!this.messaging) return;

    const tokens = await this.getUserTokens(userId);
    if (tokens.length === 0) return;

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: notification.type,
        shipmentId: notification.shipmentId || '',
        ...notification.data,
      },
      tokens,
    };

    try {
      await this.messaging.sendEachForMulticast(message);
      console.log(`FCM sent to ${tokens.length} devices for user ${userId}`);
    } catch (error) {
      console.error('FCM send error:', error);
      // Remove invalid tokens
      // In production, handle error codes to identify invalid tokens
    }
  }

  // Create notification from tracking event
  async createFromTrackingEvent(
    userId: string,
    shipment: any,
    event: any
  ): Promise<void> {
    const typeMap: Record<string, NotificationType> = {
      'CREATED': 'new_movement',
      'IN_TRANSIT': 'new_movement',
      'ARRIVED_AT_FACILITY': 'arrived_at_facility',
      'OUT_FOR_DELIVERY': 'out_for_delivery',
      'DELIVERED': 'delivered',
      'EXCEPTION': 'exception',
      'RETURNED': 'returned',
    };

    const type = typeMap[event.status] || 'new_movement';
    const prefs = await this.getPreferences(userId) as NotificationPreferences &
      Record<string, boolean | undefined>;

    // Check if this type is enabled
    if (!prefs.enabled || !prefs[type === 'arrived_at_facility' ? 'arrivedAtFacility' : type.replace('_', '')]) {
      return;
    }

    const titles: Record<NotificationType, string> = {
      new_movement: 'Yeni Hareket',
      arrived_at_facility: 'İşleme Merkezinde',
      out_for_delivery: 'Kargonuz Dağıtıma Çıktı',
      delivered: 'Teslim Edildi',
      exception: 'Kargonuzda Sorun Var',
      delay: 'Teslimat Gecikiyor',
      returned: 'Göndericiye Döndü',
    };

    await this.sendNotification({
      userId,
      title: titles[type],
      body: `${shipment.carrierName} - ${shipment.trackingNumber} ${event.description}`,
      type,
      shipmentId: shipment.id,
      data: {
        trackingNumber: shipment.trackingNumber,
        carrierCode: shipment.carrierCode,
        eventStatus: event.status,
      },
    });
  }
}

export const notificationService = new NotificationService();