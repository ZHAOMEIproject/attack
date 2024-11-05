
var e_balance = 100000000000000000n
var t_balance = 100000000000000000n
var usesend = e_balance;
let fee =0n
// BigInt(10 ** 18);

{//buy
    var tokenAmount = 
        (usesend * t_balance) /
        (e_balance + usesend);
    t_balance -= tokenAmount
    tokenAmount =tokenAmount*(100n-fee)/100n;
    e_balance += usesend;
}
console.log({
    e_balance, 
    t_balance,
    usertoken: tokenAmount
});
{//sell
    tokenAmount = tokenAmount * (100n - fee) / 100n;
    var ethAmount = (tokenAmount * e_balance) /
        (t_balance + tokenAmount);
    e_balance -= ethAmount
    t_balance += tokenAmount
}
console.log({
    e_balance, 
    t_balance,
    usereth: ethAmount - usesend
});