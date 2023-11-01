// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./library/univ3oracle.sol";
import "./interfaces/IUniswapV3Pool.sol";
contract bk_USDALOCK is Initializable, AccessControlUpgradeable,
UUPSUpgradeable {
    // 正式版需要注释的。
    uint256 fack_time;
    function changetime(uint256 _fack_time)public{
        fack_time=_fack_time;
    }
    function block_timestamp()public view returns(uint256 time){
        if(fack_time==0){
            return uint256(block.timestamp);
        }else{
            return fack_time;
        }
    }
    struct setinfo{
        uint256 _fack_time;//不设置或为0就是原本的时间
        address _exchequer;//国库地址
        pool_info _pool_info;//池子参数
        locktype[] _locktypes;//锁定周期设置
    }
    function debug(
        setinfo calldata _setinfo
    )public{
        fack_time=_setinfo._fack_time;
        exchequer=_setinfo._exchequer;
        pool=_setinfo._pool_info;
        for (uint256 i = 0; i < _setinfo._locktypes.length; i++) {
            locktypes[i]=_setinfo._locktypes[i];
        }
    }
    function show_info()public view returns(setinfo memory _setinfo){
        uint256 length=0;
        while(locktypes[length].time!=0){
            length++;
        }
        locktype[] memory s_locktypes= new locktype[](length);
        for (uint256 i = 0; i < length; i++) {
            s_locktypes[i]=locktypes[i];
        }
        _setinfo=setinfo(fack_time,exchequer,pool,s_locktypes);
    }


    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(setinfo calldata _setinfo) initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        init(_setinfo);
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
    function init(setinfo calldata _setinfo)onlyInitializing private{
        // daytime=86400;
        debug(_setinfo);
        // snapshots.push(snapshot(_setinfo._pool_info.start_time,0));
        snapshots[0]=snapshot(_setinfo._pool_info.start_time,0,0);
        snapshots_l++;
        address sender=_setinfo._exchequer;
        uint256 NGTamount=1;
        uint256 USDAamount=1;
        uint256 _type=0;
        uint256 share=NGTamount*locktypes[_type].multiple;
        orders[sender][order_l[sender]]=(order(
            share,
            USDAamount,
            NGTamount,
            _type,
            block_timestamp(),
            0,
            snapshots_l
        ));
        order_l[sender]++;
        snapshots[snapshots_l-1].totalamount+=share;
        snapshots[snapshots_l-1+(locktypes[_type].time/pool.cycle)].due+=share;
        pool.totalshare=snapshots[snapshots_l-1].totalamount;
    }
    address exchequer;
    uint constant daytime =86400;
    uint constant interesttime =86400*90;
    struct snapshot{
        uint start_time;
        uint totalamount;
        uint due;
    }
    // snapshot[] public snapshots;

    mapping(uint256=>snapshot) public snapshots;
    uint256 public snapshots_l;
    
    struct pool_info{
        address LOCK_USDA;//质押代币的地址
        uint USDA_ratio;//质押代币占比
        address LOCK_NGT;//质押代币的地址
        uint NGT_ratio;//质押代币占比
        address OUT_NGT;//获得的代币的地址
        uint256 total_reward;//总收益
        uint256 total_cycle;//总分发时间
        address LP_add;//LP池地址
        uint256 cycle;//结算周期
        uint256 totalshare;//总价值份额
        uint256 start_time;//开始时间
    }
    struct locktype{
        uint128 time;//锁定所需时间
        uint128 multiple;//锁定系数
    }
    mapping(uint256=>locktype) public locktypes;
    pool_info public pool;
    struct order{
        uint Markup_share;//加成份额
        uint U_amount;//质押数量
        uint N_amount;//NGT质押数量
        uint typeoflock;//锁定类型
        uint starttime;//锁定初始时间
        uint interest;//已取利息数量
        uint snapid;
    }
    //获取用户订单列表
    mapping(address=>mapping(uint256=>order)) public orders;
    mapping(address=>uint256) public order_l;
    struct s_order{
        order orderinfo;
        uint256 endtime;
        uint256 totalNGT;//总代币量
        uint256 reward;//可取利息数量
        uint256 b_N_amount;//销毁后的代币量
        uint256 burn;//提前提现销毁的代币量
    }

    struct interestorder{
        uint N_amount;//NGT数量
        uint starttime;//锁定初始时间
    }
    //获取用户订单列表
    mapping(address=>mapping(uint256=>interestorder)) public interestorders;
    mapping(address=>uint256) public interestorder_l;
    
    
    struct s_interestorder{
        interestorder interestorderinfo;
        uint256 endtime;
        uint256 b_N_amount;//原先代币量
        uint256 burn;//销毁的代币量
    }
    struct s_userorders{
        uint256 u_value;
        uint256 n_value;
        uint256 ngt_price;
        uint256 emissioned;
        uint256 annual_ngt;

        uint256 end_usda;
        uint256 end_ngt;


        s_order[]  _userorders;
        s_interestorder[]  _interestorders;
        uint256 availableinterest;
        uint256 interruptinterest;
        uint256 endinterest;
    }
    function getuserorders(address sender)view public returns(
        // uint256 u_value,
        // uint256 n_value,
        // uint256 ngt_price,
        // uint256 emissioned,
        // uint256 annual_ngt,

        // uint256 end_usda,
        // uint256 end_ngt,


        // s_order[]memory _userorders,
        // s_interestorder[]memory _interestorders,
        // uint256 availableinterest,
        // uint256 interruptinterest,
        // uint256 endinterest
        s_userorders memory userorders
    ){
        // uint256 totalMarkup_share;
        address n_sender=sender;
        {//_userorders
            uint256 length=order_l[n_sender];
            userorders._userorders= new s_order[](length);
            for (uint256 i = 0; i < length; i++) {
                order memory n_order=orders[n_sender][i];
                userorders.u_value+=n_order.U_amount;
                userorders.n_value+=n_order.N_amount;
                // require(false,"1??????????");
                uint256 reward = Calculate_benefits(n_order);
                // require(false,"3??????????");
                userorders.availableinterest+=reward;
                uint256 N_amount=born_cal(n_order);
                if (N_amount==n_order.N_amount) {
                    userorders.end_ngt+=N_amount;
                    userorders.end_usda+=n_order.U_amount;
                }
                userorders.annual_ngt+=end_Calculate_benefits(n_order);
                // totalMarkup_share+=n_order.Markup_share;
                uint256 _nowtime;
                if (n_order.starttime+locktypes[n_order.typeoflock].time>block_timestamp()) {
                    _nowtime=n_order.starttime+locktypes[n_order.typeoflock].time-block_timestamp();
                }
                userorders._userorders[i]=s_order(
                    n_order,
                    _nowtime,
                    reward+N_amount,
                    reward,
                    N_amount,
                    n_order.N_amount-N_amount
                );
            }
        }
        {//现在中断可提取利息
            uint256 length=interestorder_l[n_sender];
            userorders._interestorders= new s_interestorder[](length);
            for (uint256 i = 0; i < length; i++) {
                interestorder memory n_interestorder=interestorders[n_sender][i];
                uint256 N_amount=int_born_cal(n_interestorder);
                if (N_amount==n_interestorder.N_amount) {
                    userorders.endinterest+=N_amount;
                }else{
                    userorders.interruptinterest+=n_interestorder.N_amount;
                }
                // userorders.interruptinterest+=N_amount;
                uint256 burn=n_interestorder.N_amount-N_amount;
                uint256 _nowtime;
                if (n_interestorder.starttime+interesttime>block_timestamp()) {
                    _nowtime=n_interestorder.starttime+interesttime-block_timestamp();
                }
                userorders._interestorders[i]=s_interestorder(
                    n_interestorder,
                    _nowtime,
                    N_amount,
                    burn
                );
            }
        }
        {
            userorders.ngt_price=getNGTprice();
            userorders.n_value=userorders.n_value*userorders.ngt_price/(10**ERC20(pool.LOCK_USDA).decimals());
            // value=(end_ngt)*ngt_price+end_usda;
            userorders.emissioned=userorders.availableinterest;
            // annual_ngt=(pool.total_reward)*(totalMarkup_share/snapshots[snapshots.length-1].totalamount);

        }
    }
    //更新池
    function update_snapshot() public {
        snapshot memory now_snapshot = snapshots[snapshots_l-1];
        // if(now_snapshot.start_time+pool.cycle < block_timestamp()){
        //     snapshots.push(snapshot(block_timestamp(),now_snapshot.totalamount));
        // }
        while(now_snapshot.start_time+pool.cycle < block_timestamp()){
            snapshots[snapshots_l]=snapshot(
                now_snapshot.start_time+pool.cycle,
                now_snapshot.totalamount-snapshots[snapshots_l].due,
                snapshots[snapshots_l].due
            );
            now_snapshot = snapshots[snapshots_l];
            snapshots_l++;

        }
    }
    function Calculate_benefits(order memory now_order)view public returns(uint256 benefits){
        uint256 l=now_order.snapid;
        snapshot memory now_snapshot = snapshots[l-1];
        uint256 endtime=now_snapshot.start_time+locktypes[now_order.typeoflock].time;
        // require(false,uintToString(endtime));
        for(;l<snapshots_l;l++){
            if (endtime<snapshots[l].start_time) return (benefits-now_order.interest);
            benefits+=(
                (pool.total_reward/pool.total_cycle) * 
                (snapshots[l].start_time-now_snapshot.start_time) * 
                now_order.Markup_share/now_snapshot.totalamount
            );
            now_snapshot = snapshots[l];
        }
        while(
            (now_snapshot.start_time+pool.cycle <= block_timestamp())
            &&
            (now_snapshot.start_time+pool.cycle <= endtime)
        ){

            benefits+=(
                (pool.total_reward/pool.total_cycle) * 
                (pool.cycle) * 
                now_order.Markup_share/now_snapshot.totalamount
            );
            now_snapshot.start_time+=pool.cycle;
            now_snapshot.totalamount-=snapshots[l++].due;
        }
        // uint256 swap = uint256(now_order.interest);
        // benefits=benefits-swap;
        // return (benefits-swap);
        // now_order.interest=now_order.interest+0;
        // benefits=benefits-now_order.interest;



        // return benefits;
        // require(false,"2??????????");
        // require(false,uintToString(now_order.interest));
        // require(false,uintToString(benefits-now_order.interest));
        // require(false,strConcat(strConcat(uintToString(benefits),"///"),uintToString(now_order.interest)));
        // //因为已经更新过快照，应该没有新快照，但是为了拿来展示数据，还是算一下
        // if(now_snapshot.start_time+pool.cycle < block_timestamp()){
        //     if (block_timestamp()<endtime) {
        //         benefits+=(
        //             (pool.total_reward/pool.total_cycle) * 
        //             (block_timestamp()-now_snapshot.start_time) * 
        //             now_order.Markup_share/now_snapshot.totalamount
        //         );
        //     }else{
        //         benefits+=(
        //             (pool.total_reward/pool.total_cycle) * 
        //             (endtime-now_snapshot.start_time) * 
        //             now_order.Markup_share/now_snapshot.totalamount
        //         );
        //     }
        // }
        return (benefits-now_order.interest);
    }
    function end_Calculate_benefits(order memory now_order)view public returns(uint256 benefits){
        uint256 l=now_order.snapid;
        snapshot memory now_snapshot = snapshots[l-1];
        uint256 endtime=now_snapshot.start_time+locktypes[now_order.typeoflock].time;
        for(;l<snapshots_l;l++){
            if (endtime<snapshots[l].start_time) return (benefits-now_order.interest);
            now_snapshot = snapshots[l-1];
            benefits+=(
                (pool.total_reward/pool.total_cycle) * 
                (snapshots[l].start_time-now_snapshot.start_time) * 
                now_order.Markup_share/now_snapshot.totalamount
            );
        }
        while(
            (now_snapshot.start_time+pool.cycle <= block_timestamp())
            &&
            (now_snapshot.start_time+pool.cycle <= endtime)
        ){
            benefits+=(
                (pool.total_reward/pool.total_cycle) * 
                (pool.cycle) * 
                now_order.Markup_share/now_snapshot.totalamount
            );
            now_snapshot.start_time+=pool.cycle;
            now_snapshot.totalamount-=snapshots[l++].due;
        }
        if (now_order.interest==0) {
            return benefits;
        }
        // benefits+=(
        //     (pool.total_reward/pool.total_cycle) * 
        //     (endtime-now_snapshot.start_time) * 
        //     now_order.Markup_share/now_snapshot.totalamount
        // );
        return (benefits-now_order.interest);
    }
    struct permitinfo{
        address owner;
        address spender;
        uint value;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    //加入质押挖矿
    function mint(
        uint256 NGTamount,//质押的NGT数量
        uint256 _type,//质押类型
        permitinfo memory USDA_permit,//代币授权签名
        permitinfo memory NGT_permit
    ) public {
        address sender=msg.sender;
        update_snapshot();
        uint256 USDAamount=_needUSDA(NGTamount);
        ERC20Permit(pool.LOCK_USDA).permit(sender,address(this),USDA_permit.value,USDA_permit.deadline,USDA_permit.v,USDA_permit.r,USDA_permit.s);
        ERC20Permit(pool.LOCK_NGT).permit(sender,address(this),NGT_permit.value,NGT_permit.deadline,NGT_permit.v,NGT_permit.r,NGT_permit.s);
        require(ERC20(pool.LOCK_NGT).transferFrom(sender,exchequer,NGTamount),"LOCK_NGT transferFrom error");
        require(ERC20(pool.LOCK_USDA).transferFrom(sender,exchequer,USDAamount),"LOCK_USDA transferFrom error");
        uint256 share=NGTamount*locktypes[_type].multiple;
        orders[sender][order_l[sender]]=(order(
            share,
            USDAamount,
            NGTamount,
            _type,
            block_timestamp(),
            0,
            snapshots_l
        ));
        order_l[sender]++;
        snapshots[snapshots_l-1].totalamount+=share;
        snapshots[snapshots_l-1+(locktypes[_type].time/pool.cycle)].due+=share;
        pool.totalshare=snapshots[snapshots_l-1].totalamount;
    }
    function u_mint(
        uint256 USDAamount,//质押的NGT数量
        uint256 _type,//质押类型
        permitinfo memory USDA_permit,//代币授权签名
        permitinfo memory NGT_permit
    ) public {
        address sender=msg.sender;
        update_snapshot();
        // uint256 USDAamount=_needUSDA(NGTamount);
        uint256 NGTamount=_needNGT(USDAamount);
        ERC20Permit(pool.LOCK_USDA).permit(sender,address(this),USDA_permit.value,USDA_permit.deadline,USDA_permit.v,USDA_permit.r,USDA_permit.s);
        ERC20Permit(pool.LOCK_NGT).permit(sender,address(this),NGT_permit.value,NGT_permit.deadline,NGT_permit.v,NGT_permit.r,NGT_permit.s);
        require(ERC20(pool.LOCK_NGT).transferFrom(sender,exchequer,NGTamount),"LOCK_NGT transferFrom error");
        require(ERC20(pool.LOCK_USDA).transferFrom(sender,exchequer,USDAamount),"LOCK_USDA transferFrom error");
        uint256 share=NGTamount*locktypes[_type].multiple;
        orders[sender][order_l[sender]]=(order(
            share,
            USDAamount,
            NGTamount,
            _type,
            block_timestamp(),
            0,
            snapshots_l
        ));
        order_l[sender]++;
        snapshots[snapshots_l-1].totalamount+=share;
        snapshots[snapshots_l-1+(locktypes[_type].time/pool.cycle)].due+=share;
        pool.totalshare=snapshots[snapshots_l-1].totalamount;
    }
    function _needUSDA(uint256 NGTamount)public view returns(uint256 USDAamount){
        USDAamount=NGTamount*getNGTprice()*pool.USDA_ratio/pool.NGT_ratio/10**18;
    }
    function needUSDA(uint256 NGTamount)public view returns(uint256 USDAamount){
        USDAamount=NGTamount*getNGTprice()*pool.USDA_ratio/pool.NGT_ratio/10**18*101/100;
    }
    function _needNGT(uint256 USDAamount)public view returns(uint256 NGTamount){
        // USDAamount=NGTamount*getNGTprice()*pool.USDA_ratio/pool.NGT_ratio/10**18*101/100;
        // NGTamount=USDAamount/(getNGTprice()*pool.USDA_ratio/pool.NGT_ratio/10**18);
        NGTamount=USDAamount*pool.NGT_ratio*10**18/(getNGTprice()*pool.USDA_ratio);
    }
    function needNGT(uint256 USDAamount)public view returns(uint256 NGTamount){
        // USDAamount=NGTamount*getNGTprice()*pool.USDA_ratio/pool.NGT_ratio/10**18*101/100;
        NGTamount=USDAamount*pool.NGT_ratio*10**18*101/100/(getNGTprice()*pool.USDA_ratio);
    }
    function getNGTprice()public view returns(uint price){
        // (
        //     ,
        //     int24 tick,
        //     ,
        //     ,
        //     ,
        //     ,
        //     )=IUniswapV3Pool(pool.LP_add).slot0();
        // price=univ3oracle.getprice(tick, 10**18,pool.LOCK_USDA,pool.LOCK_NGT);
        price=(2.33*100)*10**(ERC20(pool.LOCK_USDA).decimals()-2);
    }
    struct s_locktype{
        uint128 time;//锁定所需时间
        uint256 annualized;//年化
    }
    function getlocktype()public view returns(s_locktype[] memory s_locktypes){
        uint256 length=0;
        while(locktypes[length].time!=0){
            length++;
        }
        s_locktypes= new s_locktype[](length);
        uint256 baseannualized=1000*10**18;
        uint256 now_totalshare=pool.totalshare;
        for (uint256 i = 0; i < 365; i++) {
            if (snapshots[snapshots_l-1].start_time+pool.cycle*(i+1) < block_timestamp()) {
                now_totalshare-=snapshots[snapshots_l+i].due;
            }else{
                break;
            }
        }
        if ((pool.total_cycle*
            now_totalshare
            // snapshots[snapshots_l-1].totalamount
            *(1000000+1000000*pool.USDA_ratio/pool.NGT_ratio)/1000000)!=0) {
            baseannualized=
                pool.total_reward*daytime*365*10**18/(pool.total_cycle//NGT年总奖励
                *
                now_totalshare
                // snapshots[snapshots_l-1].totalamount
                *(1000000+1000000*pool.USDA_ratio/pool.NGT_ratio)/1000000);//总池子价值≈NGT*2.3
        }
        if (baseannualized>1000*10**18) {
            baseannualized=1000*10**18;
        }
        for (uint256 i = 0; i < length; i++) {
            s_locktypes[i]=s_locktype(
                locktypes[i].time,
                baseannualized*locktypes[i].multiple
            );
        }
    }
    function withdraw(uint256 orderid)public{
        address sender=msg.sender;
        update_snapshot();
        order memory n_order=orders[sender][orderid];
        req_interestorder();
        uint256 new_N_amount=born_cal(n_order);
        // n_order.N_amount=born_cal(n_order);
        require(ERC20(pool.LOCK_USDA).transferFrom(exchequer,sender,n_order.U_amount),"LOCK_USDA transferFrom error");
        require(ERC20(pool.LOCK_NGT).transferFrom(exchequer,sender,new_N_amount),"LOCK_USDA transferFrom error");
        require(ERC20(pool.LOCK_NGT).transferFrom(exchequer,address(100),n_order.N_amount-new_N_amount),"LOCK_USDA transferFrom error");
        if (new_N_amount<n_order.N_amount) {
            snapshots[snapshots_l-1].totalamount-=n_order.Markup_share;
            snapshots[n_order.snapid-1+(locktypes[n_order.typeoflock].time/pool.cycle)].due-=n_order.Markup_share;
        }
        pool.totalshare=snapshots[snapshots_l-1].totalamount;
        order_del(sender,orderid);
    }
    function all_withdraw_end()public{
        address sender=msg.sender;
        update_snapshot();
        req_interestorder();
        uint256 total_U;
        uint256 total_N;
        uint256 Markup_share;
        for (uint256 i = order_l[sender]; i >0 ; i--) {
            uint256 j=i-1;
            order memory n_order=orders[sender][j];
            if (born_cal(n_order)==n_order.N_amount) {
                total_U+=n_order.U_amount;
                total_N+=n_order.N_amount;
                Markup_share+=n_order.Markup_share;
                order_del(sender,j);
            }
        }
        // snapshots[snapshots_l-1].totalamount-=Markup_share;
        pool.totalshare=snapshots[snapshots_l-1].totalamount;
        require(ERC20(pool.LOCK_USDA).transferFrom(exchequer,sender,total_U),"LOCK_USDA transferFrom error");
        require(ERC20(pool.LOCK_NGT).transferFrom(exchequer,sender,total_N),"LOCK_USDA transferFrom error");
    }
    // function withdraw_endandorderid(uint256[] memory orderids)public{
    //     for (uint256 i = 0; i < orderids.length; i++) {
    //         withdraw(orderids[i]);
    //     }
    //     all_withdraw_end();
    // }
    function born_cal(order memory n_order)public view returns(uint256 N_amount){
        N_amount=n_order.N_amount;
        if (n_order.starttime+locktypes[n_order.typeoflock].time>block_timestamp()) {
            // 销毁比例随时间从25%到90%
            // N_amount=n_order.N_amount*(10000000000000000000000-(2500000000000000000000+(locktypes[n_order.typeoflock].time-(block_timestamp()-n_order.starttime))*6500000000000000000000/locktypes[n_order.typeoflock].time))/10000000000000000000000;
            // 
            N_amount=n_order.N_amount*(10000000000000000000000-(
                0
                +(locktypes[n_order.typeoflock].time-(block_timestamp()-n_order.starttime))*
                3000000000000000000000
                /locktypes[n_order.typeoflock].time))/10000000000000000000000;
        }
    }
    function int_born_cal(interestorder memory n_interestorder)public view returns(uint256 N_amount){
        N_amount=n_interestorder.N_amount;
        if (n_interestorder.starttime+interesttime>block_timestamp()) {
            // 销毁比例随时间从0%到100%
            // N_amount=n_interestorder.N_amount*(10000000000000000000000-((interesttime-(block_timestamp()-n_interestorder.starttime))*10000000000000000000000/interesttime))/10000000000000000000000;
            // 销毁比例随时间从25%到90%
            // N_amount=n_interestorder.N_amount*(10000000000000000000000-(2500000000000000000000+(interesttime-(block_timestamp()-n_interestorder.starttime))*6500000000000000000000/interesttime))/10000000000000000000000;

            // 销毁比例随时间从0%到30%
            N_amount=n_interestorder.N_amount*(10000000000000000000000-(
                2500000000000000000000
                +(interesttime-(block_timestamp()-n_interestorder.starttime))*
                6500000000000000000000
                /interesttime))/10000000000000000000000;
        }
    }
    function order_del(address sender,uint256 orderid)private{
        order_l[sender]--;
        orders[sender][orderid]=orders[sender][order_l[sender]];
        delete orders[sender][order_l[sender]];
    }
    function interestorder_del(address sender,uint256 interestorderid)private{
        interestorder_l[sender]--;
        interestorders[sender][interestorderid]=interestorders[sender][interestorder_l[sender]];
        delete interestorders[sender][interestorder_l[sender]];
    }
    function req_interestorder()public{
        update_snapshot();
        address sender=msg.sender;
        uint256 l=order_l[sender];
        uint256 interestamount=0;
        for (uint256 i = 0; i < l; i++) {
            order memory n_order=orders[sender][i];
            uint256 reward = Calculate_benefits(n_order);
            orders[sender][i].interest+=reward;
            interestamount+=reward;
        }
        if (interestamount==0) return;
        interestorders[sender][interestorder_l[sender]]=(interestorder(
            interestamount,
            block_timestamp()
        ));
        interestorder_l[sender]++;
    }
    function withdraw_interestorder(uint256 interestorderid)public{
        address sender=msg.sender;
        interestorder memory n_interestorder=interestorders[sender][interestorderid];
        // require(n_interestorder.starttime+interesttime>block_timestamp(),"Time not yet arrived");
        n_interestorder.N_amount=int_born_cal(n_interestorder);
        require(ERC20(pool.LOCK_NGT).transferFrom(exchequer,sender,n_interestorder.N_amount),"LOCK_USDA transferFrom error");
        interestorder_del(sender,interestorderid);
    }
    function all_withdraw_interestorder()public{
        update_snapshot();
        address sender=msg.sender;
        uint256 l=interestorder_l[sender];
        uint256 interestamount=0;
        for (uint256 i = l; i >0; i--) {
            uint256 j=i-1;
            interestorder memory n_interestorder=interestorders[sender][j];
            if (n_interestorder.starttime+interesttime<block_timestamp()) {
                interestamount+=n_interestorder.N_amount;
                interestorder_del(sender,j);
            }
        }
        if (interestamount==0) return;
        require(ERC20(pool.LOCK_NGT).transferFrom(exchequer,sender,interestamount),"LOCK_USDA transferFrom error");
    }
    function toStr(uint256 value) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        //这里把数字转成了bytes32类型，但是因为我们知道数字是 0-9 ，所以前面其实都是填充了0
        bytes memory data = abi.encodePacked(value);
        bytes memory str = new bytes(1);
        //所以最后一位才是真正的数字
        uint i = data.length - 1;
        str[0] = alphabet[uint(uint8(data[i] & 0x0f))];
        return string(str);
    }

    function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
    function uintToString(uint _uint) public pure returns (string memory str) {
 
        if(_uint==0) return '0';
 
        while (_uint != 0) {
            //取模
            uint remainder = _uint % 10;
            //每取一位就移动一位，个位、十位、百位、千位……
            _uint = _uint / 10;
            //将字符拼接，注意字符位置
            str = strConcat(toStr(remainder),str);
        }
 
    }
}