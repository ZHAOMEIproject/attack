/* Start the project */

// ================Startup environment ( start_dev | start_test | start_pro )=============

start_test();

// =======================================================================================

// magicworld start Set
var node_info;
var host;
var port;

function start_test() {
    console.log("start_dev ing")
    global.secret = require("../../zm_privateinfo/.secret.js");
    global.mysqlpoolGlobal = global.secret.compliquidate.mysqlpool;
}

// Arouse the task
const timingTask = require("./task/timing-task");
timingTask.taskStart();
