const { getcontractinfo } = require('../../nodetool/id-readcontracts');

const compabi = require("./abiinfo/Comptroller.json");
const ctokenabi = require("./abiinfo/CErc20Delegator.json");

exports.scan = async function scan() {
    try {
        // var contractinfo = await getcontractinfo();
        let info = {
            comp_add: contractinfo["7156777"].Comptroller.network.address,
            blocknumber: contractinfo["7156777"].Comptroller.blocknumber,
            url: contractinfo["7156777"].Comptroller.network.url,
        }
        await compscan(info);
        console.log("end");
    } catch (error) {
        console.log(error);
    }
}

async function compscan(info) {

}
