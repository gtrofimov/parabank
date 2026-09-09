package com.parasoft.parabank.dao;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import com.parasoft.parabank.domain.Transaction;
import com.parasoft.parabank.domain.TransactionCriteria;

public class InMemoryTransactionDao implements TransactionDao {
    private static int ID = 0;

    private final List<Transaction> transactions;

    public InMemoryTransactionDao() {
        this(new ArrayList<Transaction>());
    }

    public InMemoryTransactionDao(List<Transaction> transactions) {
        this.transactions = transactions;
        ID = transactions.size();
    }

    @Override
    public Transaction getTransaction(int id) {
        for (Transaction transaction : transactions) {
            if (transaction.getId() == id) {
                return transaction;
            }
        }

        return null;
    }

    @Override
    public List<Transaction> getTransactionsForAccount(int accountId) {
        List<Transaction> accountTransactions = new ArrayList<>();

        for (Transaction transaction : transactions) {
            if (transaction.getAccountId() == accountId) {
                accountTransactions.add(transaction);
            }
        }

        return accountTransactions;
    }

    @Override
    public List<Transaction> getTransactionsForAccount(int accountId,
            TransactionCriteria criteria) {
        List<Transaction> accountTransactions = new ArrayList<>();

        for (Transaction transaction : transactions) {
            if (transaction.getAccountId() == accountId) {
                accountTransactions.add(transaction);
            }
        }

        return accountTransactions;
    }

    @Override
    public int createTransaction(Transaction transaction) {
        transaction.setId(++ID);
        transactions.add(transaction);
        return ID;
    }

    @Override
    public List<Transaction> getHighValueTransactionsForAccount(int accountId, BigDecimal threshold) {
        List<Transaction> matches = new ArrayList<>();

        for (Transaction transaction : transactions) {
            if (transaction.getAccountId() == accountId && transaction.getAmount() != null
                    && transaction.getAmount().compareTo(threshold) >= 0) {
                matches.add(transaction);
            }
        }

        matches.sort(Comparator.comparing(Transaction::getDate).reversed()
                .thenComparing(Comparator.comparingInt(Transaction::getId).reversed()));

        return matches;
    }
}
