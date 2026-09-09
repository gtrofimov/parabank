package com.parasoft.parabank.domain.logic.impl;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import org.junit.Before;
import org.junit.Test;
import org.springframework.test.annotation.Rollback;

import com.parasoft.parabank.dao.AccountDao;
import com.parasoft.parabank.dao.AdminDao;
import com.parasoft.parabank.dao.CustomerDao;
import com.parasoft.parabank.dao.InMemoryAccountDao;
import com.parasoft.parabank.dao.InMemoryAdminDao;
import com.parasoft.parabank.dao.InMemoryCustomerDao;
import com.parasoft.parabank.dao.InMemoryPositionDao;
import com.parasoft.parabank.dao.InMemoryTransactionDao;
import com.parasoft.parabank.dao.LoanRequestDao;
import com.parasoft.parabank.dao.PositionDao;
import com.parasoft.parabank.dao.TransactionDao;
import com.parasoft.parabank.domain.Account;
import com.parasoft.parabank.domain.Customer;
import com.parasoft.parabank.domain.HistoryPoint;
import com.parasoft.parabank.domain.LoanRequestHistory;
import com.parasoft.parabank.domain.LoanResponse;
import com.parasoft.parabank.domain.Position;
import com.parasoft.parabank.domain.Transaction;
import com.parasoft.parabank.domain.Transaction.TransactionType;
import com.parasoft.parabank.domain.logic.AdminParameters;
import com.parasoft.parabank.domain.logic.BankManager;
import com.parasoft.parabank.domain.logic.LoanProvider;
import com.parasoft.parabank.test.util.AbstractParaBankTest;

/**
 * @req PAR-33
 *
 */
public class BankManagerImplTest extends AbstractParaBankTest {
    private static final class CapturingLoanRequestDao implements LoanRequestDao {
        private LoanRequestHistory loanRequest;

        @Override
        public int createLoanRequest(final LoanRequestHistory loanRequest) {
            this.loanRequest = loanRequest;
            loanRequest.setId(1);
            return loanRequest.getId();
        }

        @Override
        public void updateLoanRequest(final LoanRequestHistory loanRequest) {
            this.loanRequest = loanRequest;
        }

        @Override
        public List<LoanRequestHistory> getLoanRequestsForCustomer(final int customerId) {
            return new ArrayList<>();
        }
    }

    private static final int ACCOUNT1_ID = 1;

    private static final int ACCOUNT2_ID = 2;

    private static final int ACCOUNT3_ID = 3;

    private static final int CUSTOMER_ID = 3;

    private static final String TRANSACTION_MESSAGE = "Transaction";

    private static final BigDecimal INITIAL_BALANCE = new BigDecimal("1111.11");

    private static final BigDecimal MINIMUM_BALANCE = new BigDecimal("2222.22");

    private static final int POSITION1_ID = 1;

    private static final int POSITION2_ID = 2;

    private static final String NAME = "Test Company";

    private static final String SYMBOL = "TC";

    private static final int SHARES = 10;

    private static final BigDecimal PRICEPERSHARE = new BigDecimal("10.00");

    private BankManager bankManager;

    private AccountDao accountDao;

    private CustomerDao customerDao;

    private PositionDao positionDao;

    private TransactionDao transactionDao;

    private AdminDao adminDao;

    private CapturingLoanRequestDao loanRequestDao;

    @Override
    @Before
    public void setUp() throws Exception {
        final List<Account> accounts = new ArrayList<>();

        final Account account1 = new Account();
        account1.setId(ACCOUNT1_ID);
        account1.setBalance(new BigDecimal(100));
        accounts.add(account1);

        final Account account2 = new Account();
        account2.setId(ACCOUNT2_ID);
        account2.setBalance(new BigDecimal(200));
        accounts.add(account2);

        final Account account3 = new Account();
        account3.setId(ACCOUNT3_ID);
        account3.setBalance(new BigDecimal(100));
        account3.setCustomerId(CUSTOMER_ID);
        accounts.add(account3);

        accountDao = new InMemoryAccountDao(accounts);

        final List<Customer> customers = new ArrayList<>();

        final Customer customer = new Customer();
        customer.setId(3);
        customers.add(customer);

        customerDao = new InMemoryCustomerDao(customers);

        final List<Position> positions = new ArrayList<>();

        final Position position1 = new Position();
        position1.setPositionId(POSITION1_ID);
        position1.setSymbol(SYMBOL);
        positions.add(position1);

        final Position position2 = new Position();
        position2.setPositionId(POSITION2_ID);
        position2.setSymbol(SYMBOL);
        positions.add(position2);

        final List<HistoryPoint> history = new ArrayList<>();

        HistoryPoint historyPoint = new HistoryPoint();
        final Calendar calendar = Calendar.getInstance();
        historyPoint.setDate(calendar.getTime());
        historyPoint.setSymbol(SYMBOL);
        history.add(historyPoint);

        historyPoint = new HistoryPoint();
        calendar.add(Calendar.DAY_OF_MONTH, -1);
        historyPoint.setDate(calendar.getTime());
        historyPoint.setSymbol(SYMBOL);
        history.add(historyPoint);

        positionDao = new InMemoryPositionDao(positions, history);
        transactionDao = new InMemoryTransactionDao();
        adminDao = new InMemoryAdminDao();
        loanRequestDao = new CapturingLoanRequestDao();

        adminDao.setParameter(AdminParameters.INITIAL_BALANCE, INITIAL_BALANCE.toString());
        adminDao.setParameter(AdminParameters.MINIMUM_BALANCE, MINIMUM_BALANCE.toString());

        final BankManagerImpl bankManager = new BankManagerImpl();
        bankManager.setAccountDao(accountDao);
        bankManager.setCustomerDao(customerDao);
        bankManager.setPositionDao(positionDao);
        bankManager.setTransactionDao(transactionDao);
        bankManager.setAdminDao(adminDao);
        bankManager.setLoanRequestDao(loanRequestDao);

        this.bankManager = bankManager;
    }

    @Test
    @Rollback
    public void testBuyAndSellPosition() {
        final BigDecimal AMOUNT1 = new BigDecimal(10000);
        final String NAME = "Test Company";
        final String SYMBOL = "TC";
        final int SHARES = 10;
        final BigDecimal PRICE = new BigDecimal(100);

        BigDecimal balance = bankManager.getAccount(ACCOUNT3_ID).getAvailableBalance();
        bankManager.deposit(ACCOUNT3_ID, AMOUNT1, TRANSACTION_MESSAGE);
        assertEquals(balance.add(AMOUNT1), bankManager.getAccount(ACCOUNT3_ID).getAvailableBalance());
        balance = balance.add(AMOUNT1);

        final int customerId = bankManager.getAccount(ACCOUNT3_ID).getCustomerId();
        final Customer customer = bankManager.getCustomer(customerId);
        assertEquals(customerId, customer.getId());
        final List<Position> currentList = bankManager.getPositionsForCustomer(customer);
        final int size = currentList.size();
        final int[] positionIds = new int[size];
        int iterator = 0;
        for (final Position pos : currentList) {
            positionIds[iterator] = pos.getPositionId();
            iterator++;
        }

        List<Position> positions = bankManager.buyPosition(customerId, ACCOUNT3_ID, NAME, SYMBOL, SHARES, PRICE);
        assertEquals(size + 1, positions.size());

        int newPositionId = -1;
        for (final Position pos : positions) {
            boolean found = false;
            final int id = pos.getPositionId();
            for (int positionId : positionIds) {
                if (id == positionId) {
                    found = true;
                }
            }
            if (found == false) {
                newPositionId = id;
            }
        }

        balance = balance.subtract(new BigDecimal(1000));
        Position position = bankManager.getPosition(newPositionId);
        assertNotNull(position);
        assertEquals(newPositionId, position.getPositionId());
        assertEquals(customerId, position.getCustomerId());
        assertEquals(NAME, position.getName());
        assertEquals(SYMBOL, position.getSymbol());
        assertEquals(SHARES, position.getShares());
        assertEquals(PRICE, position.getPurchasePrice());
        BigDecimal costBasis = new BigDecimal(1000);
        assertEquals(costBasis.floatValue(), position.getCostBasis().floatValue(), 0.0001f);

        Account account = bankManager.getAccount(ACCOUNT3_ID);
        BigDecimal availableBalance = account.getAvailableBalance();
        assertEquals(balance.floatValue(), availableBalance.floatValue(), 0.0001f);

        positions = bankManager.sellPosition(customerId, ACCOUNT3_ID, newPositionId, 5, PRICE);
        assertEquals(size + 1, positions.size());

        position = bankManager.getPosition(newPositionId);
        assertNotNull(position);
        assertEquals(newPositionId, position.getPositionId());
        assertEquals(customerId, position.getCustomerId());
        assertEquals(NAME, position.getName());
        assertEquals(SYMBOL, position.getSymbol());
        assertEquals(SHARES - 5, position.getShares());
        assertEquals(PRICE, position.getPurchasePrice());
        costBasis = new BigDecimal(500);
        assertEquals(costBasis.floatValue(), position.getCostBasis().floatValue(), 0.0001f);
        balance = balance.add(costBasis);
        account = bankManager.getAccount(ACCOUNT3_ID);
        availableBalance = account.getAvailableBalance();
        assertEquals(balance.floatValue(), availableBalance.floatValue(), 0.0001f);

        positions = bankManager.sellPosition(customerId, ACCOUNT3_ID, newPositionId, 5, PRICE);
        assertEquals(size, positions.size());

        position = bankManager.getPosition(newPositionId);
        assertNull(position);

        costBasis = new BigDecimal(500);
        balance = balance.add(costBasis);
        account = bankManager.getAccount(ACCOUNT3_ID);
        availableBalance = account.getAvailableBalance();
        assertEquals(balance.floatValue(), availableBalance.floatValue(), 0.0001f);
    }

    @Test
    @Rollback
    public void testCreateAccount() {
        final Account account1 = bankManager.getAccount(1);
        List<Transaction> transactions = bankManager.getTransactionsForAccount(account1);
        assertEquals(0, transactions.size());

        Account account2 = new Account();
        account2.setBalance(BigDecimal.ZERO);
        final int id = bankManager.createAccount(account2, account1.getId());
        assertEquals(id, account2.getId());

        account2 = bankManager.getAccount(account2.getId());
        assertEquals(MINIMUM_BALANCE.floatValue(), account2.getBalance().floatValue(), 0.0001f);

        transactions = bankManager.getTransactionsForAccount(account1);
        assertEquals(1, transactions.size());

        transactions = bankManager.getTransactionsForAccount(account2);
        assertEquals(1, transactions.size());
    }

    @Test
    public void testCreateCustomer() {
        final int id = bankManager.createCustomer(new Customer());
        assertEquals(2, id);
        final List<Account> accounts = accountDao.getAccountsForCustomerId(id);
        assertEquals(1, accounts.size());
        final Account account = accounts.get(0);
        assertEquals(INITIAL_BALANCE.floatValue(), account.getBalance().floatValue(), 0.0001f);
    }

    @Test
    public void testRequestLoanPersistsProviderOutcome() {
        final LoanResponse response = new LoanResponse();
        response.setApproved(true);
        response.setLoanProviderName("local");
        response.setMessage("Approved");
        response.setResponseDate(new java.util.Date());
        ((BankManagerImpl) bankManager).setLoanProvider(loanRequest -> response);

        bankManager.requestLoan(CUSTOMER_ID, new BigDecimal("500.00"), new BigDecimal("50.00"), ACCOUNT3_ID);

        assertEquals(Boolean.TRUE, loanRequestDao.loanRequest.getApproved());
        assertEquals("COMPLETED", loanRequestDao.loanRequest.getStatus());
        assertEquals("local", loanRequestDao.loanRequest.getProviderName());
        assertNotNull(loanRequestDao.loanRequest.getLoanAccountId());
    }

    @Test
    public void testGetHighValueTransactionsForAccount() {
        final Transaction lowValue = new Transaction();
        lowValue.setAccountId(ACCOUNT3_ID);
        lowValue.setType(TransactionType.Debit);
        lowValue.setDate(Calendar.getInstance().getTime());
        lowValue.setAmount(new BigDecimal("50.00"));
        lowValue.setDescription("Low value");
        transactionDao.createTransaction(lowValue);

        final Transaction highValue = new Transaction();
        highValue.setAccountId(ACCOUNT3_ID);
        highValue.setType(TransactionType.Credit);
        highValue.setDate(Calendar.getInstance().getTime());
        highValue.setAmount(new BigDecimal("1500.00"));
        highValue.setDescription("High value");
        transactionDao.createTransaction(highValue);

        final List<Transaction> result =
            bankManager.getHighValueTransactionsForAccount(ACCOUNT3_ID, new BigDecimal("1000.00"));

        assertEquals(1, result.size());
        assertEquals(0, new BigDecimal("1500.00").compareTo(result.get(0).getAmount()));
    }

    @Test
    public void testCreatePosition() {
        final Position position = bankManager.createPosition(CUSTOMER_ID, NAME, SYMBOL, SHARES, PRICEPERSHARE);
        assertNotNull(position);
        assertEquals(CUSTOMER_ID, position.getCustomerId());
        assertEquals(NAME, position.getName());
        assertEquals(SYMBOL, position.getSymbol());
        assertEquals(SHARES, position.getShares());
        assertEquals(PRICEPERSHARE.floatValue(), position.getPurchasePrice().floatValue(), 0.0001f);
    }

    @Test
    public void testDeposit() {
        final BigDecimal AMOUNT1 = new BigDecimal(50);

        bankManager.deposit(ACCOUNT1_ID, AMOUNT1, TRANSACTION_MESSAGE);

        final Account account1 = accountDao.getAccount(ACCOUNT1_ID);
        assertEquals(new BigDecimal(150).floatValue(), account1.getBalance().floatValue(), 0.0001f);
        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT1_ID).size());

        Transaction transaction = transactionDao.getTransactionsForAccount(ACCOUNT1_ID).get(0);
        assertEquals(ACCOUNT1_ID, transaction.getAccountId());
        assertEquals(TransactionType.Credit, transaction.getType());
        assertEquals(AMOUNT1.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals(TRANSACTION_MESSAGE, transaction.getDescription());

        final BigDecimal AMOUNT2 = new BigDecimal(300);

        bankManager.deposit(ACCOUNT2_ID, AMOUNT2, TRANSACTION_MESSAGE);

        final Account account2 = accountDao.getAccount(ACCOUNT2_ID);
        assertEquals(new BigDecimal(500).floatValue(), account2.getBalance().floatValue(), 0.0001f);
        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT2_ID).size());

        transaction = transactionDao.getTransactionsForAccount(ACCOUNT2_ID).get(0);
        assertEquals(ACCOUNT2_ID, transaction.getAccountId());
        assertEquals(TransactionType.Credit, transaction.getType());
        assertEquals(AMOUNT2.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals(TRANSACTION_MESSAGE, transaction.getDescription());
    }

    @Test
    public void testTransfer() {
        final BigDecimal AMOUNT = new BigDecimal(50);

        bankManager.transfer(ACCOUNT1_ID, ACCOUNT2_ID, AMOUNT);

        Account account1 = accountDao.getAccount(ACCOUNT1_ID);
        assertEquals(new BigDecimal(50).floatValue(), account1.getBalance().floatValue(), 0.0001f);

        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT1_ID).size());

        Transaction transaction = transactionDao.getTransactionsForAccount(ACCOUNT1_ID).get(0);
        assertEquals(ACCOUNT1_ID, transaction.getAccountId());
        assertEquals(TransactionType.Debit, transaction.getType());
        assertEquals(AMOUNT.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals("Funds Transfer Sent", transaction.getDescription());

        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT2_ID).size());

        transaction = transactionDao.getTransactionsForAccount(ACCOUNT2_ID).get(0);
        assertEquals(ACCOUNT2_ID, transaction.getAccountId());
        assertEquals(TransactionType.Credit, transaction.getType());
        assertEquals(AMOUNT.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals("Funds Transfer Received", transaction.getDescription());

        Account account2 = accountDao.getAccount(ACCOUNT2_ID);
        assertEquals(new BigDecimal(250).floatValue(), account2.getBalance().floatValue(), 0.0001f);

        bankManager.transfer(ACCOUNT2_ID, ACCOUNT1_ID, new BigDecimal(100));

        account1 = accountDao.getAccount(ACCOUNT1_ID);
        account2 = accountDao.getAccount(ACCOUNT2_ID);
        assertEquals(account1.getBalance().floatValue(), account2.getBalance().floatValue(), 0.0001f);

        assertEquals(2, transactionDao.getTransactionsForAccount(ACCOUNT1_ID).size());

        transaction = transactionDao.getTransactionsForAccount(ACCOUNT1_ID).get(0);
        assertEquals(ACCOUNT1_ID, transaction.getAccountId());
        assertEquals(TransactionType.Debit, transaction.getType());
        assertEquals(AMOUNT.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals("Funds Transfer Sent", transaction.getDescription());

        assertEquals(2, transactionDao.getTransactionsForAccount(ACCOUNT2_ID).size());

        transaction = transactionDao.getTransactionsForAccount(ACCOUNT2_ID).get(0);
        assertEquals(ACCOUNT2_ID, transaction.getAccountId());
        assertEquals(TransactionType.Credit, transaction.getType());
        assertEquals(AMOUNT.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals("Funds Transfer Received", transaction.getDescription());
    }

    @Test
    public void testWithdraw() {
        final BigDecimal AMOUNT1 = new BigDecimal(50);

        bankManager.withdraw(ACCOUNT1_ID, AMOUNT1, TRANSACTION_MESSAGE);

        final Account account1 = accountDao.getAccount(ACCOUNT1_ID);
        assertEquals(new BigDecimal(50).floatValue(), account1.getBalance().floatValue(), 0.0001f);
        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT1_ID).size());

        Transaction transaction = transactionDao.getTransactionsForAccount(ACCOUNT1_ID).get(0);
        assertEquals(ACCOUNT1_ID, transaction.getAccountId());
        assertEquals(TransactionType.Debit, transaction.getType());
        assertEquals(AMOUNT1.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals(TRANSACTION_MESSAGE, transaction.getDescription());

        final BigDecimal AMOUNT2 = new BigDecimal(300);

        bankManager.withdraw(ACCOUNT2_ID, AMOUNT2, TRANSACTION_MESSAGE);

        final Account account2 = accountDao.getAccount(ACCOUNT2_ID);
        assertEquals(new BigDecimal(-100).floatValue(), account2.getBalance().floatValue(), 0.0001f);
        assertEquals(1, transactionDao.getTransactionsForAccount(ACCOUNT2_ID).size());

        transaction = transactionDao.getTransactionsForAccount(ACCOUNT2_ID).get(0);
        assertEquals(ACCOUNT2_ID, transaction.getAccountId());
        assertEquals(TransactionType.Debit, transaction.getType());
        assertEquals(AMOUNT2.floatValue(), transaction.getAmount().floatValue(), 0.0001f);
        assertEquals(TRANSACTION_MESSAGE, transaction.getDescription());
    }
}
