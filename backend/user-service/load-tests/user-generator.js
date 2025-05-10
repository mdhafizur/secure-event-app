module.exports = {
    generateUser: function (context, events, done) {
        const roles = ['user', 'admin'];
        const randomRole = roles[Math.floor(Math.random() * roles.length)];

        context.vars.user = {
            username: `user_${Math.random().toString(36).substring(7)}`,
            email: `user_${Date.now()}_${Math.floor(Math.random() * 1000)}@test.com`,
            password: 'P@ssw0rd123',
            role: randomRole
        };
        return done();
    }
};
