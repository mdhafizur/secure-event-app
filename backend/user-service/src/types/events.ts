export interface UserEvent {
    type: 'USER_CREATED' | 'USER_DELETED' | 'USER_UPDATED';
    data: {
        userId: string;
        username: string;
        email: string;
        role?: string;
        timestamp: string;
    };
}

export const USER_EVENTS_TOPIC = 'user-events';
