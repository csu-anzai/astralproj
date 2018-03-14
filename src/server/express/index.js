const Express = require("express"),
			Helmet = require("helmet"),
			Serve = Express();
Serve.use(Helmet);
Serve.listen(3000);
module.exports = Serve;