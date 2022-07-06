![Project Image](https://miro.medium.com/max/1838/1*hLl5yEjcYk9jQ8E8i7izWw.png)


### Vesting Smart Contract

- [Description](#description)
- [Technologies](#technologies)
- [How To Use](#how-to-use)
- [API Endpoint](#api-endpoint)
- [License](#license)
- [Author Info](#author-info)

---

## Description

###  Vesting Smart Contract implementation using an ERC20 token which provides functionality to lock in tokens for a specfic period of time before transfering them to the users.

## Technologies

- Truffle
- Web3JS
- VSCode
- Git Bash

---

# How To Use
---

## Installation


Clone the repo:

```bash
git clone https://github.com/mailer3261/vestingContract.git
cd vestingContract
```

Install dependencies:

```bash
npm install
```

Set environment variables:

```bash
- create a .env file in project Directory.
- set the following variables,
    OWNER = "public_key_of_owner"
    MNUEMONIC_KEY = "12_words_mnuemonic_to_initiate_a_transaction"
    NETWORK_URL = networkurl_of_an_apinode_to_connect_to_blockchain
```

## Running Locally

```bash
Start truffle inbuilt blockchain node - truffle develop
to compile - compile
to migrate- migrate
```

---
# Testing ....

Test cases are written for testing various functions

### First, we need to create an ERC20 token whose address will be given as input while deploying

```bash
provide value 1 as input to ERC20 contract while deployment which creates an initial supply of 10^18 tokens.
```

### Once token contract is deployed, we take its address as input and provide it as an input to vesting contract while deployment

```bash
ERC20 : address
```

### Initially the Cliff and Vesting Duration period is set to "0", as if not then we will have to wait for a certain period of time before releasing the tokens.

```bash
ERC20 : address
```


### Functions

```bash
### allocateTokensForRoles
- addBeneficiary
- revokeBeneficiary
- releaseTokens
- withdrawTokens
- getTokensReleased
- getTokensWithdrawn

Note:- Apart from these there are some other internal funtions.
```

### allocateTokensForRoles.

```bash
- it allocates contract token balance to specific roles based on a certain predefined percentage
```


### Get Transactions for

```bash
GET \ http://localhost:8080/view/transactions

along with the request, we need to manually copy the authorization token received in the previous login response headers and set it to "Authorization" as a Bearer token and paste the Hash.
```
## License and Copyright

Copyright © 2022
Solulab Pvt Ltd.
India

## Author Info

- GitHub - [@mailer3261](https://github.com/mailer3261)

[Back To The Top](#read-me-template)

