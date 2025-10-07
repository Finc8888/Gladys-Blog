---
title: "4 принципа ООП: Полное руководство с примерами"
description: "Разбираем четыре фундаментальных принципа объектно-ориентированного программирования: инкапсуляция, наследование, полиморфизм и абстракция"
date: 2025-10-07
tldr: "Изучаем основы ООП: инкапсуляция, наследование, полиморфизм и абстракция с практическими примерами на PHP и Go"
draft: false
tags: ["программирование", "ооп", "php", "golang", "архитектура", "разработка"]
toc: true
---

# 4 принципа ООП: Фундамент объектно-ориентированного программирования

Объектно-ориентированное программирование (ООП) — это парадигма разработки, основанная на концепции "объектов", которые содержат данные и код для работы с этими данными. ООП строится на четырех фундаментальных принципах, понимание которых критически важно для любого разработчика.

### Что такое ООП?

ООП — это способ организации кода, при котором программа представляется как набор взаимодействующих объектов. Каждый объект является экземпляром класса — шаблона, определяющего структуру и поведение объектов.

**Основные понятия:**

- **Класс** — шаблон или чертеж для создания объектов
- **Объект** — конкретный экземпляр класса
- **Свойства (атрибуты)** — данные, характеризующие объект
- **Методы** — функции, определяющие поведение объекта

---

## Принцип 1: Инкапсуляция (Encapsulation)

### Что это такое?

**Инкапсуляция** — это сокрытие внутренней реализации объекта и предоставление доступа к его данным только через публичные методы. Это как автомобиль: вы знаете, как им управлять (руль, педали), но не обязаны знать, как работает двигатель внутри.

**Цели инкапсуляции:**
- Защита данных от некорректного использования
- Скрытие сложности реализации
- Упрощение изменения внутренней логики без влияния на внешний код
- Контроль доступа к данным

### Уровни доступа

**PHP:**
- `public` — доступен везде
- `protected` — доступен в классе и его наследниках
- `private` — доступен только внутри класса

**Go:**
- Заглавная буква — экспортируемый (публичный)
- Строчная буква — не экспортируемый (приватный)

### Пример на PHP

```php
<?php

class BankAccount {
    // Приватные свойства - скрыты от внешнего доступа
    private float $balance;
    private string $accountNumber;
    private array $transactionHistory = [];

    public function __construct(string $accountNumber, float $initialBalance = 0) {
        $this->accountNumber = $accountNumber;
        $this->balance = $initialBalance;
        $this->addTransaction("Открытие счета", $initialBalance);
    }

    // Публичный метод для пополнения
    public function deposit(float $amount): bool {
        if ($amount <= 0) {
            throw new InvalidArgumentException("Сумма должна быть положительной");
        }

        $this->balance += $amount;
        $this->addTransaction("Пополнение", $amount);
        return true;
    }

    // Публичный метод для снятия
    public function withdraw(float $amount): bool {
        if ($amount <= 0) {
            throw new InvalidArgumentException("Сумма должна быть положительной");
        }

        if (!$this->hasSufficientFunds($amount)) {
            throw new Exception("Недостаточно средств");
        }

        $this->balance -= $amount;
        $this->addTransaction("Снятие", -$amount);
        return true;
    }

    // Публичный геттер - контролируемый доступ к балансу
    public function getBalance(): float {
        return $this->balance;
    }

    public function getAccountNumber(): string {
        return $this->accountNumber;
    }

    public function getTransactionHistory(): array {
        return $this->transactionHistory;
    }

    // Приватный метод - внутренняя логика
    private function hasSufficientFunds(float $amount): bool {
        return $this->balance >= $amount;
    }

    // Приватный метод для логирования транзакций
    private function addTransaction(string $type, float $amount): void {
        $this->transactionHistory[] = [
            'date' => date('Y-m-d H:i:s'),
            'type' => $type,
            'amount' => $amount,
            'balance' => $this->balance
        ];
    }
}

// Использование
$account = new BankAccount("123456789", 1000);

// Правильный способ - через публичные методы
$account->deposit(500);
echo "Баланс: " . $account->getBalance(); // 1500

$account->withdraw(300);
echo "Баланс: " . $account->getBalance(); // 1200

// Неправильный способ - прямой доступ запрещен
// $account->balance = 1000000; // ОШИБКА! Fatal error
// $account->addTransaction(...); // ОШИБКА! Приватный метод
```

### Пример на Go

```go
package main

import (
    "errors"
    "fmt"
    "time"
)

// Transaction представляет транзакцию
type Transaction struct {
    Date    time.Time
    Type    string
    Amount  float64
    Balance float64
}

// BankAccount - структура с приватными полями (строчные буквы)
type BankAccount struct {
    balance            float64       // приватное поле
    accountNumber      string        // приватное поле
    transactionHistory []Transaction // приватное поле
}

// NewBankAccount - конструктор (публичная функция)
func NewBankAccount(accountNumber string, initialBalance float64) *BankAccount {
    account := &BankAccount{
        accountNumber:      accountNumber,
        balance:            initialBalance,
        transactionHistory: make([]Transaction, 0),
    }
    account.addTransaction("Открытие счета", initialBalance)
    return account
}

// Deposit - публичный метод для пополнения (заглавная буква)
func (a *BankAccount) Deposit(amount float64) error {
    if amount <= 0 {
        return errors.New("сумма должна быть положительной")
    }

    a.balance += amount
    a.addTransaction("Пополнение", amount)
    return nil
}

// Withdraw - публичный метод для снятия
func (a *BankAccount) Withdraw(amount float64) error {
    if amount <= 0 {
        return errors.New("сумма должна быть положительной")
    }

    if !a.hasSufficientFunds(amount) {
        return errors.New("недостаточно средств")
    }

    a.balance -= amount
    a.addTransaction("Снятие", -amount)
    return nil
}

// GetBalance - публичный геттер (заглавная буква)
func (a *BankAccount) GetBalance() float64 {
    return a.balance
}

// GetAccountNumber - публичный геттер
func (a *BankAccount) GetAccountNumber() string {
    return a.accountNumber
}

// GetTransactionHistory - публичный геттер
func (a *BankAccount) GetTransactionHistory() []Transaction {
    // Возвращаем копию, чтобы защитить внутренние данные
    history := make([]Transaction, len(a.transactionHistory))
    copy(history, a.transactionHistory)
    return history
}

// hasSufficientFunds - приватный метод (строчная буква)
func (a *BankAccount) hasSufficientFunds(amount float64) bool {
    return a.balance >= amount
}

// addTransaction - приватный метод
func (a *BankAccount) addTransaction(transactionType string, amount float64) {
    transaction := Transaction{
        Date:    time.Now(),
        Type:    transactionType,
        Amount:  amount,
        Balance: a.balance,
    }
    a.transactionHistory = append(a.transactionHistory, transaction)
}

func main() {
    account := NewBankAccount("123456789", 1000)

    // Правильный способ - через публичные методы
    account.Deposit(500)
    fmt.Printf("Баланс: %.2f\n", account.GetBalance()) // 1500

    account.Withdraw(300)
    fmt.Printf("Баланс: %.2f\n", account.GetBalance()) // 1200

    // Неправильный способ - прямой доступ невозможен из другого пакета
    // account.balance = 1000000 // ОШИБКА при компиляции
    // account.addTransaction(...) // ОШИБКА при компиляции
}
```

**Преимущества инкапсуляции:**
- Нельзя установить отрицательный баланс напрямую
- Все изменения логируются автоматически
- Можно изменить внутреннюю реализацию без изменения внешнего API
- Валидация данных в одном месте

---

## Принцип 2: Наследование (Inheritance)

### Что это такое?

**Наследование** — это механизм создания новых классов на основе существующих. Дочерний класс (наследник) получает все свойства и методы родительского класса и может добавлять свои или переопределять унаследованные.

**Аналогия:** Биологическое наследование — ребенок наследует черты родителей, но также имеет свои уникальные особенности.

**Зачем нужно:**
- Переиспользование кода
- Создание иерархии классов
- Расширение функциональности без изменения базового класса
- Реализация принципа DRY (Don't Repeat Yourself)

### Пример на PHP

```php
<?php

// Базовый класс - общие свойства всех животных
abstract class Animal {
    protected string $name;
    protected int $age;
    protected float $weight;

    public function __construct(string $name, int $age, float $weight) {
        $this->name = $name;
        $this->age = $age;
        $this->weight = $weight;
    }

    // Общий метод для всех животных
    public function eat(float $foodWeight): void {
        $this->weight += $foodWeight * 0.1;
        echo "{$this->name} поел(а) и теперь весит {$this->weight} кг\n";
    }

    public function sleep(): void {
        echo "{$this->name} спит...\n";
    }

    public function getInfo(): string {
        return "Имя: {$this->name}, Возраст: {$this->age}, Вес: {$this->weight} кг";
    }

    // Абстрактный метод - должен быть реализован в наследниках
    abstract public function makeSound(): void;
}

// Наследник - Собака
class Dog extends Animal {
    private string $breed;
    private bool $isTrained;

    public function __construct(string $name, int $age, float $weight, string $breed) {
        parent::__construct($name, $age, $weight); // Вызов конструктора родителя
        $this->breed = $breed;
        $this->isTrained = false;
    }

    // Реализация абстрактного метода
    public function makeSound(): void {
        echo "{$this->name} гавкает: Гав-гав!\n";
    }

    // Уникальный метод для собак
    public function fetch(): void {
        echo "{$this->name} приносит мячик\n";
    }

    public function train(): void {
        $this->isTrained = true;
        echo "{$this->name} обучен(а) командам!\n";
    }

    // Переопределение метода родителя
    public function getInfo(): string {
        $parentInfo = parent::getInfo(); // Получаем базовую информацию
        $trained = $this->isTrained ? "обучен(а)" : "не обучен(а)";
        return "$parentInfo, Порода: {$this->breed}, {$trained}";
    }
}

// Наследник - Кошка
class Cat extends Animal {
    private int $livesLeft;

    public function __construct(string $name, int $age, float $weight) {
        parent::__construct($name, $age, $weight);
        $this->livesLeft = 9; // У кошек 9 жизней
    }

    public function makeSound(): void {
        echo "{$this->name} мяукает: Мяу-мяу!\n";
    }

    // Уникальный метод для кошек
    public function scratch(): void {
        echo "{$this->name} точит когти об диван\n";
    }

    public function useLive(): void {
        if ($this->livesLeft > 0) {
            $this->livesLeft--;
            echo "{$this->name} потерял(а) жизнь. Осталось: {$this->livesLeft}\n";
        }
    }

    public function getInfo(): string {
        $parentInfo = parent::getInfo();
        return "$parentInfo, Жизней осталось: {$this->livesLeft}";
    }
}

// Наследник - Птица
class Bird extends Animal {
    private float $wingSpan;
    private bool $canFly;

    public function __construct(string $name, int $age, float $weight, float $wingSpan, bool $canFly = true) {
        parent::__construct($name, $age, $weight);
        $this->wingSpan = $wingSpan;
        $this->canFly = $canFly;
    }

    public function makeSound(): void {
        echo "{$this->name} чирикает: Чик-чирик!\n";
    }

    public function fly(): void {
        if ($this->canFly) {
            echo "{$this->name} летит с размахом крыльев {$this->wingSpan} см\n";
        } else {
            echo "{$this->name} не может летать\n";
        }
    }
}

// Использование
$dog = new Dog("Бобик", 3, 15.5, "Лабрадор");
echo $dog->getInfo() . "\n";
$dog->makeSound();
$dog->eat(0.5);
$dog->fetch();
$dog->train();
echo $dog->getInfo() . "\n\n";

$cat = new Cat("Мурка", 2, 4.2);
echo $cat->getInfo() . "\n";
$cat->makeSound();
$cat->scratch();
$cat->useLive();
echo $cat->getInfo() . "\n\n";

$bird = new Bird("Кеша", 1, 0.3, 25);
echo $bird->getInfo() . "\n";
$bird->makeSound();
$bird->fly();

// Полиморфизм через наследование
function feedAnimal(Animal $animal): void {
    $animal->eat(0.5);
}

feedAnimal($dog);
feedAnimal($cat);
feedAnimal($bird);
```

### Пример на Go (композиция вместо наследования)

**Важно:** В Go нет классического наследования. Вместо этого используется **композиция** и **интерфейсы**. Это более гибкий подход.

```go
package main

import "fmt"

// Animal - базовая структура (встраиваемая)
type Animal struct {
    name   string
    age    int
    weight float64
}

// Конструктор для Animal
func NewAnimal(name string, age int, weight float64) Animal {
    return Animal{
        name:   name,
        age:    age,
        weight: weight,
    }
}

// Методы Animal
func (a *Animal) Eat(foodWeight float64) {
    a.weight += foodWeight * 0.1
    fmt.Printf("%s поел(а) и теперь весит %.2f кг\n", a.name, a.weight)
}

func (a *Animal) Sleep() {
    fmt.Printf("%s спит...\n", a.name)
}

func (a *Animal) GetInfo() string {
    return fmt.Sprintf("Имя: %s, Возраст: %d, Вес: %.2f кг", a.name, a.age, a.weight)
}

// Интерфейс - контракт для всех животных
type SoundMaker interface {
    MakeSound()
}

// Dog - композиция: встраивает Animal
type Dog struct {
    Animal          // встроенная структура (anonymous field)
    breed     string
    isTrained bool
}

// Конструктор для Dog
func NewDog(name string, age int, weight float64, breed string) *Dog {
    return &Dog{
        Animal:    NewAnimal(name, age, weight),
        breed:     breed,
        isTrained: false,
    }
}

// Реализация интерфейса SoundMaker
func (d *Dog) MakeSound() {
    fmt.Printf("%s гавкает: Гав-гав!\n", d.name)
}

// Уникальные методы Dog
func (d *Dog) Fetch() {
    fmt.Printf("%s приносит мячик\n", d.name)
}

func (d *Dog) Train() {
    d.isTrained = true
    fmt.Printf("%s обучен(а) командам!\n", d.name)
}

// Переопределение метода GetInfo
func (d *Dog) GetInfo() string {
    baseInfo := d.Animal.GetInfo() // Вызов метода встроенной структуры
    trained := "не обучен(а)"
    if d.isTrained {
        trained = "обучен(а)"
    }
    return fmt.Sprintf("%s, Порода: %s, %s", baseInfo, d.breed, trained)
}

// Cat - композиция
type Cat struct {
    Animal
    livesLeft int
}

func NewCat(name string, age int, weight float64) *Cat {
    return &Cat{
        Animal:    NewAnimal(name, age, weight),
        livesLeft: 9,
    }
}

func (c *Cat) MakeSound() {
    fmt.Printf("%s мяукает: Мяу-мяу!\n", c.name)
}

func (c *Cat) Scratch() {
    fmt.Printf("%s точит когти об диван\n", c.name)
}

func (c *Cat) UseLive() {
    if c.livesLeft > 0 {
        c.livesLeft--
        fmt.Printf("%s потерял(а) жизнь. Осталось: %d\n", c.name, c.livesLeft)
    }
}

func (c *Cat) GetInfo() string {
    baseInfo := c.Animal.GetInfo()
    return fmt.Sprintf("%s, Жизней осталось: %d", baseInfo, c.livesLeft)
}

// Bird - композиция
type Bird struct {
    Animal
    wingSpan float64
    canFly   bool
}

func NewBird(name string, age int, weight float64, wingSpan float64, canFly bool) *Bird {
    return &Bird{
        Animal:   NewAnimal(name, age, weight),
        wingSpan: wingSpan,
        canFly:   canFly,
    }
}

func (b *Bird) MakeSound() {
    fmt.Printf("%s чирикает: Чик-чирик!\n", b.name)
}

func (b *Bird) Fly() {
    if b.canFly {
        fmt.Printf("%s летит с размахом крыльев %.2f см\n", b.name, b.wingSpan)
    } else {
        fmt.Printf("%s не может летать\n", b.name)
    }
}

// Полиморфизм через интерфейс
func makeAnimalSound(animal SoundMaker) {
    animal.MakeSound()
}

func main() {
    dog := NewDog("Бобик", 3, 15.5, "Лабрадор")
    fmt.Println(dog.GetInfo())
    dog.MakeSound()
    dog.Eat(0.5)
    dog.Fetch()
    dog.Train()
    fmt.Println(dog.GetInfo())
    fmt.Println()

    cat := NewCat("Мурка", 2, 4.2)
    fmt.Println(cat.GetInfo())
    cat.MakeSound()
    cat.Scratch()
    cat.UseLive()
    fmt.Println(cat.GetInfo())
    fmt.Println()

    bird := NewBird("Кеша", 1, 0.3, 25, true)
    fmt.Println(bird.GetInfo())
    bird.MakeSound()
    bird.Fly()
    fmt.Println()

    // Полиморфизм через интерфейс
    animals := []SoundMaker{dog, cat, bird}
    for _, animal := range animals {
        makeAnimalSound(animal)
    }
}
```

**Ключевые отличия:**
- PHP: классическое наследование через `extends`
- Go: композиция через встраивание структур и интерфейсы для полиморфизма

---

## Принцип 3: Полиморфизм (Polymorphism)

### Что это такое?

**Полиморфизм** (от греч. "много форм") — это возможность объектов с одинаковым интерфейсом иметь различную реализацию. Один и тот же метод может вести себя по-разному в зависимости от типа объекта.

**Типы полиморфизма:**
1. **Полиморфизм подтипов** — через наследование/интерфейсы
2. **Параметрический полиморфизм** — generic-типы (Go 1.18+)
3. **Ad-hoc полиморфизм** — перегрузка методов (PHP не поддерживает)

### Пример на PHP

```php
<?php

// Интерфейс для оплаты
interface PaymentMethod {
    public function processPayment(float $amount): bool;
    public function getTransactionFee(float $amount): float;
    public function getPaymentInfo(): string;
}

// Оплата кредитной картой
class CreditCardPayment implements PaymentMethod {
    private string $cardNumber;
    private string $cardHolder;
    private string $cvv;

    public function __construct(string $cardNumber, string $cardHolder, string $cvv) {
        $this->cardNumber = $cardNumber;
        $this->cardHolder = $cardHolder;
        $this->cvv = $cvv;
    }

    public function processPayment(float $amount): bool {
        $fee = $this->getTransactionFee($amount);
        $total = $amount + $fee;

        echo "Обработка платежа по карте **** " . substr($this->cardNumber, -4) . "\n";
        echo "Сумма: {$amount} руб + комиссия: {$fee} руб = {$total} руб\n";

        // Имитация обработки платежа
        sleep(1);
        echo "Платеж успешно проведен!\n\n";
        return true;
    }

    public function getTransactionFee(float $amount): float {
        return $amount * 0.025; // 2.5% комиссия
    }

    public function getPaymentInfo(): string {
        return "Кредитная карта: **** " . substr($this->cardNumber, -4);
    }
}

// Оплата через PayPal
class PayPalPayment implements PaymentMethod {
    private string $email;

    public function __construct(string $email) {
        $this->email = $email;
    }

    public function processPayment(float $amount): bool {
        $fee = $this->getTransactionFee($amount);
        $total = $amount + $fee;

        echo "Обработка платежа через PayPal ({$this->email})\n";
        echo "Сумма: {$amount} руб + комиссия: {$fee} руб = {$total} руб\n";

        sleep(1);
        echo "Платеж успешно проведен через PayPal!\n\n";
        return true;
    }

    public function getTransactionFee(float $amount): float {
        return $amount * 0.034 + 10; // 3.4% + 10 руб фиксированная комиссия
    }

    public function getPaymentInfo(): string {
        return "PayPal: {$this->email}";
    }
}

// Оплата криптовалютой
class CryptoPayment implements PaymentMethod {
    private string $walletAddress;
    private string $currency;

    public function __construct(string $walletAddress, string $currency = "BTC") {
        $this->walletAddress = $walletAddress;
        $this->currency = $currency;
    }

    public function processPayment(float $amount): bool {
        $fee = $this->getTransactionFee($amount);
        $total = $amount + $fee;

        echo "Обработка платежа в {$this->currency}\n";
        echo "Адрес кошелька: " . substr($this->walletAddress, 0, 10) . "...\n";
        echo "Сумма: {$amount} руб + комиссия сети: {$fee} руб = {$total} руб\n";

        sleep(2); // Криптоплатежи обрабатываются дольше
        echo "Транзакция отправлена в блокчейн!\n\n";
        return true;
    }

    public function getTransactionFee(float $amount): float {
        return 50; // Фиксированная комиссия сети
    }

    public function getPaymentInfo(): string {
        return "Криптовалюта {$this->currency}: " . substr($this->walletAddress, 0, 10) . "...";
    }
}

// Класс заказа, использующий полиморфизм
class Order {
    private string $orderId;
    private float $totalAmount;
    private array $items;

    public function __construct(string $orderId, array $items) {
        $this->orderId = $orderId;
        $this->items = $items;
        $this->totalAmount = array_sum(array_column($items, 'price'));
    }

    // Метод принимает ЛЮБОЙ объект, реализующий PaymentMethod
    // Это и есть полиморфизм!
    public function checkout(PaymentMethod $paymentMethod): bool {
        echo "========================================\n";
        echo "Заказ №{$this->orderId}\n";
        echo "Товаров: " . count($this->items) . "\n";
        echo "Сумма: {$this->totalAmount} руб\n";
        echo "Способ оплаты: " . $paymentMethod->getPaymentInfo() . "\n";
        echo "========================================\n\n";

        // Вызываем processPayment, но реализация зависит от типа объекта
        return $paymentMethod->processPayment($this->totalAmount);
    }
}

// Использование
$items = [
    ['name' => 'Ноутбук', 'price' => 50000],
    ['name' => 'Мышка', 'price' => 1000],
    ['name' => 'Клавиатура', 'price' => 3000]
];

$order1 = new Order("ORD-001", $items);
$order2 = new Order("ORD-002", $items);
$order3 = new Order("ORD-003", $items);

// Один и тот же метод checkout работает с разными способами оплаты
$creditCard = new CreditCardPayment("1234567890123456", "Ivan Ivanov", "123");
$order1->checkout($creditCard);

$paypal = new PayPalPayment("user@example.com");
$order2->checkout($paypal);

$crypto = new CryptoPayment("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", "BTC");
$order3->checkout($crypto);

// Можно легко добавить новый способ оплаты, не меняя код Order
class BankTransferPayment implements PaymentMethod {
    private string $accountNumber;

    public function __construct(string $accountNumber) {
        $this->accountNumber = $accountNumber;
    }

    public function processPayment(float $amount): bool {
        echo "Банковский перевод на счет {$this->accountNumber}\n";
        echo "Сумма: {$amount} руб (без комиссии)\n";
        echo "Платеж обрабатывается банком...\n\n";
        return true;
    }

    public function getTransactionFee(float $amount): float {
        return 0; // Без комиссии
    }

    public function getPaymentInfo(): string {
        return "Банковский перевод: {$this->accountNumber}";
    }
}

$order4 = new Order("ORD-004", $items);
$bankTransfer = new BankTransferPayment("40817810099910004312");
$order4->checkout($bankTransfer);
```

### Пример на Go

```go
package main

import (
    "fmt"
    "strings"
    "time"
)

// PaymentMethod - интерфейс для всех способов оплаты
type PaymentMethod interface {
    ProcessPayment(amount float64) bool
    GetTransactionFee(amount float64) float64
    GetPaymentInfo() string
}

// CreditCardPayment - оплата картой
type CreditCardPayment struct {
    cardNumber string
    cardHolder string
    cvv        string
}

func NewCreditCardPayment(cardNumber, cardHolder, cvv string) *CreditCardPayment {
    return &CreditCardPayment{
        cardNumber: cardNumber,
        cardHolder: cardHolder,
        cvv:        cvv,
    }
}

func (c *CreditCardPayment) ProcessPayment(amount float64) bool {
    fee := c.GetTransactionFee(amount)
    total := amount + fee

    lastFour := c.cardNumber[len(c.cardNumber)-4:]
    fmt.Printf("Обработка платежа по карте **** %s\n", lastFour)
    fmt.Printf("Сумма: %.2f руб + комиссия: %.2f руб = %.2f руб\n", amount, fee, total)

    time.Sleep(1 * time.Second)
    fmt.Println("Платеж успешно проведен!\n")
    return true
}

func (c *CreditCardPayment) GetTransactionFee(amount float64) float64 {
    return amount * 0.025 // 2.5% комиссия
}

func (c *CreditCardPayment) GetPaymentInfo() string {
    lastFour := c.cardNumber[len(c.cardNumber)-4:]
    return fmt.Sprintf("Кредитная карта: **** %s", lastFour)
}

// PayPalPayment - оплата через PayPal
type PayPalPayment struct {
    email string
}

func NewPayPalPayment(email string) *PayPalPayment {
    return &PayPalPayment{email: email}
}

func (p *PayPalPayment) ProcessPayment(amount float64) bool {
    fee := p.GetTransactionFee(amount)
    total := amount + fee

    fmt.Printf("Обработка платежа через PayPal (%s)\n", p.email)
    fmt.Printf("Сумма: %.2f руб + комиссия: %.2f руб = %.2f руб\n", amount, fee, total)

    time.Sleep(1 * time.Second)
    fmt.Println("Платеж успешно проведен через PayPal!\n")
    return true
}

func (p *PayPalPayment) GetTransactionFee(amount float64) float64 {
    return amount*0.034 + 10 // 3.4% + 10 руб
}

func (p *PayPalPayment) GetPaymentInfo() string {
    return fmt.Sprintf("PayPal: %s", p.email)
}

// CryptoPayment - оплата криптовалютой
type CryptoPayment struct {
    walletAddress string
    currency      string
}

func NewCryptoPayment(walletAddress, currency string) *CryptoPayment {
    return &CryptoPayment{
        walletAddress: walletAddress,
        currency:      currency,
    }
}

func (cr *CryptoPayment) ProcessPayment(amount float64) bool {
    fee := cr.GetTransactionFee(amount)
    total := amount + fee

    fmt.Printf("Обработка платежа в %s\n", cr.currency)
    fmt.Printf("Адрес кошелька: %s...\n", cr.walletAddress[:10])
    fmt.Printf("Сумма: %.2f руб + комиссия сети: %.2f руб = %.2f руб\n", amount, fee, total)

    time.Sleep(2 * time.Second)
    fmt.Println("Транзакция отправлена в блокчейн!\n")
    return true
}

func (cr *CryptoPayment) GetTransactionFee(amount float64) float64 {
    return 50 // Фиксированная комиссия сети
}

func (cr *CryptoPayment) GetPaymentInfo() string {
    return fmt.Sprintf("Криптовалюта %s: %s...", cr.currency, cr.walletAddress[:10])
}

// Item - товар в заказе
type Item struct {
    Name  string
    Price float64
}

// Order - заказ
type Order struct {
    orderID     string
    totalAmount float64
    items       []Item
}

func NewOrder(orderID string, items []Item) *Order {
    total := 0.0
    for _, item := range items {
        total += item.Price
    }

    return &Order{
        orderID:     orderID,
        totalAmount: total,
        items:       items,
    }
}

// Checkout - метод принимает ЛЮБОЙ тип, реализующий интерфейс PaymentMethod
// Это полиморфизм!
func (o *Order) Checkout(paymentMethod PaymentMethod) bool {
    fmt.Println(strings.Repeat("=", 40))
    fmt.Printf("Заказ №%s\n", o.orderID)
    fmt.Printf("Товаров: %d\n", len(o.items))
    fmt.Printf("Сумма: %.2f руб\n", o.totalAmount)
    fmt.Printf("Способ оплаты: %s\n", paymentMethod.GetPaymentInfo())
    fmt.Println(strings.Repeat("=", 40))
    fmt.Println()

    return paymentMethod.ProcessPayment(o.totalAmount)
}

// BankTransferPayment - банковский перевод
type BankTransferPayment struct {
    accountNumber string
}

func NewBankTransferPayment(accountNumber string) *BankTransferPayment {
    return &BankTransferPayment{accountNumber: accountNumber}
}

func (b *BankTransferPayment) ProcessPayment(amount float64) bool {
    fmt.Printf("Банковский перевод на счет %s\n", b.accountNumber)
    fmt.Printf("Сумма: %.2f руб (без комиссии)\n", amount)
    fmt.Println("Платеж обрабатывается банком...\n")
    return true
}

func (b *BankTransferPayment) GetTransactionFee(amount float64) float64 {
    return 0 // Без комиссии
}

func (b *BankTransferPayment) GetPaymentInfo() string {
    return fmt.Sprintf("Банковский перевод: %s", b.accountNumber)
}

func main() {
    items := []Item{
        {Name: "Ноутбук", Price: 50000},
        {Name: "Мышка", Price: 1000},
        {Name: "Клавиатура", Price: 3000},
    }

    // Создаем заказы
    order1 := NewOrder("ORD-001", items)
    order2 := NewOrder("ORD-002", items)
    order3 := NewOrder("ORD-003", items)
    order4 := NewOrder("ORD-004", items)

    // Один и тот же метод Checkout работает с разными способами оплаты
    creditCard := NewCreditCardPayment("1234567890123456", "Ivan Ivanov", "123")
    order1.Checkout(creditCard)

    paypal := NewPayPalPayment("user@example.com")
    order2.Checkout(paypal)

    crypto := NewCryptoPayment("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", "BTC")
    order3.Checkout(crypto)

    bankTransfer := NewBankTransferPayment("40817810099910004312")
    order4.Checkout(bankTransfer)
}
```

**Преимущества полиморфизма:**
- Единый интерфейс для разных реализаций
- Легко добавлять новые типы без изменения существующего кода
- Код становится более гибким и расширяемым
- Упрощает тестирование (можно создавать mock-объекты)

---

## Принцип 4: Абстракция (Abstraction)

### Что это такое?

**Абстракция** — это выделение существенных характеристик объекта и игнорирование несущественных. Абстракция позволяет работать с объектами на более высоком уровне, не вдаваясь в детали реализации.

**Цели абстракции:**
- Упростить сложные системы
- Скрыть детали реализации
- Создать общий контракт (интерфейс)
- Сфокусироваться на том, **что** делает объект, а не **как**

**Инструменты:**
- Абстрактные классы (PHP)
- Интерфейсы (PHP, Go)
- Абстрактные методы

### Пример на PHP

```php
<?php

// Абстрактный класс - нельзя создать экземпляр напрямую
abstract class DatabaseConnection {
    protected string $host;
    protected string $database;
    protected string $username;
    protected string $password;
    protected $connection = null;

    public function __construct(string $host, string $database, string $username, string $password) {
        $this->host = $host;
        $this->database = $database;
        $this->username = $username;
        $this->password = $password;
    }

    // Абстрактные методы - должны быть реализованы в наследниках
    abstract public function connect(): bool;
    abstract public function disconnect(): void;
    abstract public function query(string $sql): array;
    abstract public function execute(string $sql): bool;
    abstract public function lastInsertId(): int;

    // Конкретный метод - общий для всех БД
    public function isConnected(): bool {
        return $this->connection !== null;
    }

    // Шаблонный метод - определяет общий алгоритм
    public function executeTransaction(array $queries): bool {
        try {
            $this->beginTransaction();

            foreach ($queries as $query) {
                if (!$this->execute($query)) {
                    $this->rollback();
                    return false;
                }
            }

            $this->commit();
            return true;
        } catch (Exception $e) {
            $this->rollback();
            throw $e;
        }
    }

    abstract protected function beginTransaction(): void;
    abstract protected function commit(): void;
    abstract protected function rollback(): void;
}

// Конкретная реализация для MySQL
class MySQLConnection extends DatabaseConnection {
    public function connect(): bool {
        echo "Подключение к MySQL: {$this->host}/{$this->database}\n";

        try {
            $this->connection = new PDO(
                "mysql:host={$this->host};dbname={$this->database}",
                $this->username,
                $this->password,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
            echo "✓ MySQL подключен\n";
            return true;
        } catch (PDOException $e) {
            echo "✗ Ошибка подключения: {$e->getMessage()}\n";
            return false;
        }
    }

    public function disconnect(): void {
        $this->connection = null;
        echo "✓ MySQL отключен\n";
    }

    public function query(string $sql): array {
        echo "MySQL Query: {$sql}\n";
        $stmt = $this->connection->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function execute(string $sql): bool {
        echo "MySQL Execute: {$sql}\n";
        return $this->connection->exec($sql) !== false;
    }

    public function lastInsertId(): int {
        return (int)$this->connection->lastInsertId();
    }

    protected function beginTransaction(): void {
        $this->connection->beginTransaction();
        echo "→ MySQL транзакция начата\n";
    }

    protected function commit(): void {
        $this->connection->commit();
        echo "✓ MySQL транзакция завершена\n";
    }

    protected function rollback(): void {
        $this->connection->rollBack();
        echo "✗ MySQL транзакция отменена\n";
    }
}

// Конкретная реализация для PostgreSQL
class PostgreSQLConnection extends DatabaseConnection {
    public function connect(): bool {
        echo "Подключение к PostgreSQL: {$this->host}/{$this->database}\n";

        try {
            $this->connection = new PDO(
                "pgsql:host={$this->host};dbname={$this->database}",
                $this->username,
                $this->password,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
            echo "✓ PostgreSQL подключен\n";
            return true;
        } catch (PDOException $e) {
            echo "✗ Ошибка подключения: {$e->getMessage()}\n";
            return false;
        }
    }

    public function disconnect(): void {
        $this->connection = null;
        echo "✓ PostgreSQL отключен\n";
    }

    public function query(string $sql): array {
        echo "PostgreSQL Query: {$sql}\n";
        $stmt = $this->connection->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function execute(string $sql): bool {
        echo "PostgreSQL Execute: {$sql}\n";
        return $this->connection->exec($sql) !== false;
    }

    public function lastInsertId(): int {
        // В PostgreSQL используется другой подход
        $result = $this->query("SELECT lastval()");
        return (int)$result[0]['lastval'];
    }

    protected function beginTransaction(): void {
        $this->connection->beginTransaction();
        echo "→ PostgreSQL транзакция начата\n";
    }

    protected function commit(): void {
        $this->connection->commit();
        echo "✓ PostgreSQL транзакция завершена\n";
    }

    protected function rollback(): void {
        $this->connection->rollBack();
        echo "✗ PostgreSQL транзакция отменена\n";
    }
}

// Конкретная реализация для SQLite
class SQLiteConnection extends DatabaseConnection {
    public function __construct(string $filepath) {
        parent::__construct($filepath, '', '', '');
    }

    public function connect(): bool {
        echo "Подключение к SQLite: {$this->host}\n";

        try {
            $this->connection = new PDO("sqlite:{$this->host}");
            $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            echo "✓ SQLite подключен\n";
            return true;
        } catch (PDOException $e) {
            echo "✗ Ошибка подключения: {$e->getMessage()}\n";
            return false;
        }
    }

    public function disconnect(): void {
        $this->connection = null;
        echo "✓ SQLite отключен\n";
    }

    public function query(string $sql): array {
        echo "SQLite Query: {$sql}\n";
        $stmt = $this->connection->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function execute(string $sql): bool {
        echo "SQLite Execute: {$sql}\n";
        return $this->connection->exec($sql) !== false;
    }

    public function lastInsertId(): int {
        return (int)$this->connection->lastInsertId();
    }

    protected function beginTransaction(): void {
        $this->connection->beginTransaction();
        echo "→ SQLite транзакция начата\n";
    }

    protected function commit(): void {
        $this->connection->commit();
        echo "✓ SQLite транзакция завершена\n";
    }

    protected function rollback(): void {
        $this->connection->rollBack();
        echo "✗ SQLite транзакция отменена\n";
    }
}

// Класс, использующий абстракцию
class UserRepository {
    private DatabaseConnection $db;

    // Принимаем любую реализацию DatabaseConnection
    public function __construct(DatabaseConnection $db) {
        $this->db = $db;
    }

    public function createUser(string $name, string $email): int {
        $sql = "INSERT INTO users (name, email) VALUES ('{$name}', '{$email}')";
        $this->db->execute($sql);
        return $this->db->lastInsertId();
    }

    public function getUser(int $id): ?array {
        $result = $this->db->query("SELECT * FROM users WHERE id = {$id}");
        return $result[0] ?? null;
    }

    public function updateUser(int $id, string $name, string $email): bool {
        $sql = "UPDATE users SET name = '{$name}', email = '{$email}' WHERE id = {$id}";
        return $this->db->execute($sql);
    }

    public function deleteUser(int $id): bool {
        return $this->db->execute("DELETE FROM users WHERE id = {$id}");
    }
}

// Использование
echo "=== Работа с MySQL ===\n";
$mysql = new MySQLConnection("localhost", "mydb", "root", "password");
$mysql->connect();

$userRepo1 = new UserRepository($mysql);
// ... работа с репозиторием

$mysql->disconnect();

echo "\n=== Работа с PostgreSQL ===\n";
$postgres = new PostgreSQLConnection("localhost", "mydb", "user", "password");
$postgres->connect();

$userRepo2 = new UserRepository($postgres);
// ... работа с репозиторием

$postgres->disconnect();

echo "\n=== Работа с SQLite ===\n";
$sqlite = new SQLiteConnection("database.db");
$sqlite->connect();

$userRepo3 = new UserRepository($sqlite);
// ... работа с репозиторием

$sqlite->disconnect();

// Демонстрация транзакций
echo "\n=== Тестирование транзакций ===\n";
$mysql->connect();
$queries = [
    "INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')",
    "INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com')",
    "INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com')"
];
$mysql->executeTransaction($queries);
$mysql->disconnect();
```

### Пример на Go

```go
package main

import (
    "database/sql"
    "fmt"
    "log"

    _ "github.com/mattn/go-sqlite3"
)

// DatabaseConnection - интерфейс для работы с БД (абстракция)
type DatabaseConnection interface {
    Connect() error
    Disconnect() error
    Query(sql string) ([]map[string]interface{}, error)
    Execute(sql string) error
    LastInsertID() (int64, error)
    IsConnected() bool

    // Транзакции
    BeginTransaction() error
    Commit() error
    Rollback() error
}

// BaseConnection - базовая структура с общей функциональностью
type BaseConnection struct {
    host       string
    database   string
    username   string
    password   string
    connection *sql.DB
    tx         *sql.Tx
}

func (b *BaseConnection) IsConnected() bool {
    return b.connection != nil
}

// ExecuteTransaction - шаблонный метод для транзакций
func ExecuteTransaction(db DatabaseConnection, queries []string) error {
    if err := db.BeginTransaction(); err != nil {
        return err
    }

    for _, query := range queries {
        if err := db.Execute(query); err != nil {
            db.Rollback()
            return err
        }
    }

    return db.Commit()
}

// MySQLConnection - реализация для MySQL
type MySQLConnection struct {
    BaseConnection
}

func NewMySQLConnection(host, database, username, password string) *MySQLConnection {
    return &MySQLConnection{
        BaseConnection: BaseConnection{
            host:     host,
            database: database,
            username: username,
            password: password,
        },
    }
}

func (m *MySQLConnection) Connect() error {
    fmt.Printf("Подключение к MySQL: %s/%s\n", m.host, m.database)

    dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s", m.username, m.password, m.host, m.database)
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        fmt.Printf("✗ Ошибка подключения: %v\n", err)
        return err
    }

    m.connection = db
    fmt.Println("✓ MySQL подключен")
    return nil
}

func (m *MySQLConnection) Disconnect() error {
    if m.connection != nil {
        err := m.connection.Close()
        m.connection = nil
        fmt.Println("✓ MySQL отключен")
        return err
    }
    return nil
}

func (m *MySQLConnection) Query(sqlQuery string) ([]map[string]interface{}, error) {
    fmt.Printf("MySQL Query: %s\n", sqlQuery)

    rows, err := m.connection.Query(sqlQuery)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    return rowsToMaps(rows)
}

func (m *MySQLConnection) Execute(sqlQuery string) error {
    fmt.Printf("MySQL Execute: %s\n", sqlQuery)

    var err error
    if m.tx != nil {
        _, err = m.tx.Exec(sqlQuery)
    } else {
        _, err = m.connection.Exec(sqlQuery)
    }
    return err
}

func (m *MySQLConnection) LastInsertID() (int64, error) {
    var id int64
    err := m.connection.QueryRow("SELECT LAST_INSERT_ID()").Scan(&id)
    return id, err
}

func (m *MySQLConnection) BeginTransaction() error {
    tx, err := m.connection.Begin()
    if err != nil {
        return err
    }
    m.tx = tx
    fmt.Println("→ MySQL транзакция начата")
    return nil
}

func (m *MySQLConnection) Commit() error {
    if m.tx == nil {
        return fmt.Errorf("нет активной транзакции")
    }
    err := m.tx.Commit()
    m.tx = nil
    fmt.Println("✓ MySQL транзакция завершена")
    return err
}

func (m *MySQLConnection) Rollback() error {
    if m.tx == nil {
        return fmt.Errorf("нет активной транзакции")
    }
    err := m.tx.Rollback()
    m.tx = nil
    fmt.Println("✗ MySQL транзакция отменена")
    return err
}

// SQLiteConnection - реализация для SQLite
type SQLiteConnection struct {
    BaseConnection
}

func NewSQLiteConnection(filepath string) *SQLiteConnection {
    return &SQLiteConnection{
        BaseConnection: BaseConnection{
            host: filepath,
        },
    }
}

func (s *SQLiteConnection) Connect() error {
    fmt.Printf("Подключение к SQLite: %s\n", s.host)

    db, err := sql.Open("sqlite3", s.host)
    if err != nil {
        fmt.Printf("✗ Ошибка подключения: %v\n", err)
        return err
    }

    s.connection = db
    fmt.Println("✓ SQLite подключен")
    return nil
}

func (s *SQLiteConnection) Disconnect() error {
    if s.connection != nil {
        err := s.connection.Close()
        s.connection = nil
        fmt.Println("✓ SQLite отключен")
        return err
    }
    return nil
}

func (s *SQLiteConnection) Query(sqlQuery string) ([]map[string]interface{}, error) {
    fmt.Printf("SQLite Query: %s\n", sqlQuery)

    rows, err := s.connection.Query(sqlQuery)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    return rowsToMaps(rows)
}

func (s *SQLiteConnection) Execute(sqlQuery string) error {
    fmt.Printf("SQLite Execute: %s\n", sqlQuery)

    var err error
    if s.tx != nil {
        _, err = s.tx.Exec(sqlQuery)
    } else {
        _, err = s.connection.Exec(sqlQuery)
    }
    return err
}

func (s *SQLiteConnection) LastInsertID() (int64, error) {
    var id int64
    err := s.connection.QueryRow("SELECT last_insert_rowid()").Scan(&id)
    return id, err
}

func (s *SQLiteConnection) BeginTransaction() error {
    tx, err := s.connection.Begin()
    if err != nil {
        return err
    }
    s.tx = tx
    fmt.Println("→ SQLite транзакция начата")
    return nil
}

func (s *SQLiteConnection) Commit() error {
    if s.tx == nil {
        return fmt.Errorf("нет активной транзакции")
    }
    err := s.tx.Commit()
    s.tx = nil
    fmt.Println("✓ SQLite транзакция завершена")
    return err
}

func (s *SQLiteConnection) Rollback() error {
    if s.tx == nil {
        return fmt.Errorf("нет активной транзакции")
    }
    err := s.tx.Rollback()
    s.tx = nil
    fmt.Println("✗ SQLite транзакция отменена")
    return err
}

// Вспомогательная функция для конвертации строк в map
func rowsToMaps(rows *sql.Rows) ([]map[string]interface{}, error) {
    columns, err := rows.Columns()
    if err != nil {
        return nil, err
    }

    var results []map[string]interface{}

    for rows.Next() {
        values := make([]interface{}, len(columns))
        valuePtrs := make([]interface{}, len(columns))

        for i := range columns {
            valuePtrs[i] = &values[i]
        }

        if err := rows.Scan(valuePtrs...); err != nil {
            return nil, err
        }

        row := make(map[string]interface{})
        for i, col := range columns {
            row[col] = values[i]
        }

        results = append(results, row)
    }

    return results, nil
}

// UserRepository - репозиторий, использующий абстракцию
type UserRepository struct {
    db DatabaseConnection
}

func NewUserRepository(db DatabaseConnection) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) CreateUser(name, email string) (int64, error) {
    sql := fmt.Sprintf("INSERT INTO users (name, email) VALUES ('%s', '%s')", name, email)
    if err := r.db.Execute(sql); err != nil {
        return 0, err
    }
    return r.db.LastInsertID()
}

func (r *UserRepository) GetUser(id int64) (map[string]interface{}, error) {
    sql := fmt.Sprintf("SELECT * FROM users WHERE id = %d", id)
    results, err := r.db.Query(sql)
    if err != nil {
        return nil, err
    }

    if len(results) == 0 {
        return nil, fmt.Errorf("пользователь не найден")
    }

    return results[0], nil
}

func (r *UserRepository) UpdateUser(id int64, name, email string) error {
    sql := fmt.Sprintf("UPDATE users SET name = '%s', email = '%s' WHERE id = %d", name, email, id)
    return r.db.Execute(sql)
}

func (r *UserRepository) DeleteUser(id int64) error {
    sql := fmt.Sprintf("DELETE FROM users WHERE id = %d", id)
    return r.db.Execute(sql)
}

func main() {
    // Демонстрация работы с SQLite
    fmt.Println("=== Работа с SQLite ===")
    sqlite := NewSQLiteConnection(":memory:")

    if err := sqlite.Connect(); err != nil {
        log.Fatal(err)
    }
    defer sqlite.Disconnect()

    // Создаем таблицу
    sqlite.Execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)")

    // Используем репозиторий
    userRepo := NewUserRepository(sqlite)

    // Создаем пользователей
    id1, _ := userRepo.CreateUser("Alice", "alice@example.com")
    fmt.Printf("Создан пользователь с ID: %d\n", id1)

    id2, _ := userRepo.CreateUser("Bob", "bob@example.com")
    fmt.Printf("Создан пользователь с ID: %d\n", id2)

    // Получаем пользователя
    user, _ := userRepo.GetUser(id1)
    fmt.Printf("Получен пользователь: %v\n", user)

    // Обновляем пользователя
    userRepo.UpdateUser(id1, "Alice Smith", "alice.smith@example.com")
    fmt.Println("Пользователь обновлен")

    fmt.Println("\n=== Тестирование транзакций ===")
    queries := []string{
        "INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com')",
        "INSERT INTO users (name, email) VALUES ('David', 'david@example.com')",
        "INSERT INTO users (name, email) VALUES ('Eve', 'eve@example.com')",
    }

```go
    if err := ExecuteTransaction(sqlite, queries); err != nil {
        log.Fatal(err)
    }

    // Проверяем результаты
    allUsers, _ := sqlite.Query("SELECT * FROM users")
    fmt.Printf("\nВсего пользователей в базе: %d\n", len(allUsers))
    for _, user := range allUsers {
        fmt.Printf("  - ID: %v, Name: %v, Email: %v\n", user["id"], user["name"], user["email"])
    }
}
```

**Преимущества абстракции:**
- Можно легко менять реализацию БД без изменения бизнес-логики
- Упрощает тестирование (можно создать mock-реализацию)
- Код становится более модульным и понятным
- Изменения в одной реализации не влияют на другие

---

## Взаимосвязь принципов ООП

Четыре принципа ООП не существуют изолированно — они дополняют друг друга:

### Как они работают вместе

```php
<?php

// АБСТРАКЦИЯ - определяем контракт
interface Logger {
    public function log(string $message, string $level): void;
}

// ИНКАПСУЛЯЦИЯ - скрываем детали реализации
class FileLogger implements Logger {
    private string $filepath;
    private $fileHandle;

    public function __construct(string $filepath) {
        $this->filepath = $filepath;
        $this->openFile(); // Приватная логика
    }

    // Приватный метод - детали скрыты
    private function openFile(): void {
        $this->fileHandle = fopen($this->filepath, 'a');
    }

    private function formatMessage(string $message, string $level): string {
        $timestamp = date('Y-m-d H:i:s');
        return "[{$timestamp}] [{$level}] {$message}\n";
    }

    // Публичный интерфейс
    public function log(string $message, string $level = 'INFO'): void {
        $formatted = $this->formatMessage($message, $level);
        fwrite($this->fileHandle, $formatted);
    }

    public function __destruct() {
        if ($this->fileHandle) {
            fclose($this->fileHandle);
        }
    }
}

// НАСЛЕДОВАНИЕ и ПОЛИМОРФИЗМ
class DatabaseLogger implements Logger {
    private PDO $connection;

    public function __construct(PDO $connection) {
        $this->connection = $connection;
    }

    // Та же сигнатура, но другая реализация
    public function log(string $message, string $level = 'INFO'): void {
        $sql = "INSERT INTO logs (message, level, created_at) VALUES (?, ?, NOW())";
        $stmt = $this->connection->prepare($sql);
        $stmt->execute([$message, $level]);
    }
}

class ConsoleLogger implements Logger {
    private array $colors = [
        'INFO' => "\033[0;32m",    // зеленый
        'WARNING' => "\033[0;33m",  // желтый
        'ERROR' => "\033[0;31m",    // красный
        'RESET' => "\033[0m"
    ];

    public function log(string $message, string $level = 'INFO'): void {
        $color = $this->colors[$level] ?? $this->colors['INFO'];
        $reset = $this->colors['RESET'];
        echo "{$color}[{$level}] {$message}{$reset}\n";
    }
}

// ПОЛИМОРФИЗМ - одна функция работает с разными реализациями
class Application {
    private Logger $logger;

    public function __construct(Logger $logger) {
        $this->logger = $logger;
    }

    public function run(): void {
        $this->logger->log("Приложение запущено", "INFO");

        try {
            $this->doSomething();
        } catch (Exception $e) {
            $this->logger->log("Ошибка: " . $e->getMessage(), "ERROR");
        }

        $this->logger->log("Приложение завершено", "INFO");
    }

    private function doSomething(): void {
        $this->logger->log("Выполняем операцию...", "INFO");
        // ... логика
    }
}

// Использование - легко меняем реализацию
$fileLogger = new FileLogger('app.log');
$app1 = new Application($fileLogger);
$app1->run();

$consoleLogger = new ConsoleLogger();
$app2 = new Application($consoleLogger);
$app2->run();

// $dbLogger = new DatabaseLogger($pdo);
// $app3 = new Application($dbLogger);
// $app3->run();
```

---

## Практические примеры: Реальные задачи

### Пример 1: Система уведомлений

```php
<?php

// Абстракция
interface NotificationChannel {
    public function send(string $recipient, string $message): bool;
    public function supports(string $type): bool;
}

// Инкапсуляция
class EmailNotification implements NotificationChannel {
    private string $smtpHost;
    private int $smtpPort;
    private string $username;
    private string $password;

    public function __construct(string $host, int $port, string $user, string $pass) {
        $this->smtpHost = $host;
        $this->smtpPort = $port;
        $this->username = $user;
        $this->password = $pass;
    }

    public function send(string $recipient, string $message): bool {
        echo "Отправка email на {$recipient}\n";
        echo "Сообщение: {$message}\n";
        // Логика отправки через SMTP
        return true;
    }

    public function supports(string $type): bool {
        return $type === 'email';
    }

    private function connectSMTP(): void {
        // Приватная логика подключения
    }
}

class SMSNotification implements NotificationChannel {
    private string $apiKey;
    private string $provider;

    public function __construct(string $apiKey, string $provider = 'twilio') {
        $this->apiKey = $apiKey;
        $this->provider = $provider;
    }

    public function send(string $recipient, string $message): bool {
        echo "Отправка SMS на {$recipient} через {$this->provider}\n";
        echo "Сообщение: {$message}\n";
        // Логика отправки через API
        return true;
    }

    public function supports(string $type): bool {
        return $type === 'sms';
    }
}

class PushNotification implements NotificationChannel {
    private string $fcmToken;

    public function __construct(string $token) {
        $this->fcmToken = $token;
    }

    public function send(string $recipient, string $message): bool {
        echo "Отправка Push-уведомления на устройство {$recipient}\n";
        echo "Сообщение: {$message}\n";
        // Логика отправки через FCM/APNs
        return true;
    }

    public function supports(string $type): bool {
        return $type === 'push';
    }
}

// Полиморфизм - единый интерфейс для всех каналов
class NotificationService {
    private array $channels = [];

    public function addChannel(NotificationChannel $channel): void {
        $this->channels[] = $channel;
    }

    public function notify(string $recipient, string $message, string $type): bool {
        foreach ($this->channels as $channel) {
            if ($channel->supports($type)) {
                return $channel->send($recipient, $message);
            }
        }

        throw new Exception("Канал для типа '{$type}' не найден");
    }

    public function notifyAll(string $recipient, string $message): void {
        foreach ($this->channels as $channel) {
            $channel->send($recipient, $message);
        }
    }
}

// Использование
$notificationService = new NotificationService();
$notificationService->addChannel(new EmailNotification('smtp.gmail.com', 587, 'user', 'pass'));
$notificationService->addChannel(new SMSNotification('api-key-123'));
$notificationService->addChannel(new PushNotification('fcm-token-456'));

// Отправляем через конкретный канал
$notificationService->notify('user@example.com', 'Ваш заказ готов!', 'email');
$notificationService->notify('+79001234567', 'Код подтверждения: 1234', 'sms');

// Отправляем через все каналы
$notificationService->notifyAll('user@example.com', 'Важное уведомление!');
```

### Пример 2: Обработка платежей (расширенный)

```php
<?php

abstract class PaymentGateway {
    protected float $processingFee = 0;
    protected string $currency = 'RUB';

    // Шаблонный метод - определяет алгоритм
    final public function process(float $amount, array $details): array {
        $this->validate($amount, $details);
        $this->beforePayment($amount);

        $result = $this->executePayment($amount, $details);

        if ($result['success']) {
            $this->afterSuccessfulPayment($amount, $result);
        } else {
            $this->afterFailedPayment($amount, $result);
        }

        return $result;
    }

    // Абстрактные методы - реализуются наследниками
    abstract protected function executePayment(float $amount, array $details): array;
    abstract protected function validate(float $amount, array $details): void;

    // Хуки - можно переопределить в наследниках
    protected function beforePayment(float $amount): void {
        echo "Подготовка к платежу на сумму {$amount} {$this->currency}\n";
    }

    protected function afterSuccessfulPayment(float $amount, array $result): void {
        echo "✓ Платеж успешно проведен. ID транзакции: {$result['transaction_id']}\n";
        $this->sendReceipt($result);
    }

    protected function afterFailedPayment(float $amount, array $result): void {
        echo "✗ Платеж отклонен: {$result['error']}\n";
        $this->notifyAdmin($result);
    }

    protected function sendReceipt(array $result): void {
        echo "Отправка чека на email...\n";
    }

    protected function notifyAdmin(array $result): void {
        echo "Уведомление администратора об ошибке...\n";
    }

    public function calculateTotal(float $amount): float {
        return $amount + ($amount * $this->processingFee);
    }
}

class StripePayment extends PaymentGateway {
    protected float $processingFee = 0.029; // 2.9%
    private string $apiKey;

    public function __construct(string $apiKey) {
        $this->apiKey = $apiKey;
    }

    protected function validate(float $amount, array $details): void {
        if ($amount < 0.5) {
            throw new Exception("Минимальная сумма для Stripe: 0.5 USD");
        }

        if (empty($details['card_token'])) {
            throw new Exception("Не указан токен карты");
        }
    }

    protected function executePayment(float $amount, array $details): array {
        echo "→ Обращение к Stripe API...\n";
        sleep(1); // Имитация запроса

        // Имитация успешного платежа
        return [
            'success' => true,
            'transaction_id' => 'stripe_' . uniqid(),
            'amount' => $amount,
            'fee' => $amount * $this->processingFee,
            'net_amount' => $amount - ($amount * $this->processingFee)
        ];
    }
}

class PayPalPayment extends PaymentGateway {
    protected float $processingFee = 0.034; // 3.4%
    private string $clientId;
    private string $clientSecret;

    public function __construct(string $clientId, string $clientSecret) {
        $this->clientId = $clientId;
        $this->clientSecret = $clientSecret;
    }

    protected function validate(float $amount, array $details): void {
        if ($amount < 1) {
            throw new Exception("Минимальная сумма для PayPal: 1 USD");
        }

        if (empty($details['payer_email'])) {
            throw new Exception("Не указан email плательщика");
        }
    }

    protected function executePayment(float $amount, array $details): array {
        echo "→ Обращение к PayPal API...\n";
        sleep(1);

        return [
            'success' => true,
            'transaction_id' => 'paypal_' . uniqid(),
            'amount' => $amount,
            'fee' => $amount * $this->processingFee + 10,
            'payer_email' => $details['payer_email']
        ];
    }

    // Переопределяем хук
    protected function afterSuccessfulPayment(float $amount, array $result): void {
        parent::afterSuccessfulPayment($amount, $result);
        echo "Отправка уведомления PayPal на {$result['payer_email']}\n";
    }
}

class RobokassaPayment extends PaymentGateway {
    protected float $processingFee = 0.05; // 5%
    protected string $currency = 'RUB';
    private string $merchantId;
    private string $secretKey;

    public function __construct(string $merchantId, string $secretKey) {
        $this->merchantId = $merchantId;
        $this->secretKey = $secretKey;
    }

    protected function validate(float $amount, array $details): void {
        if ($amount < 10) {
            throw new Exception("Минимальная сумма для Робокассы: 10 RUB");
        }
    }

    protected function executePayment(float $amount, array $details): array {
        echo "→ Перенаправление на страницу Робокассы...\n";
        sleep(2);

        $signature = md5("{$this->merchantId}:{$amount}:{$this->secretKey}");

        return [
            'success' => true,
            'transaction_id' => 'robokassa_' . uniqid(),
            'amount' => $amount,
            'fee' => $amount * $this->processingFee,
            'signature' => $signature
        ];
    }
}

// Использование
echo "=== Платеж через Stripe ===\n";
$stripe = new StripePayment('sk_test_123456');
$result1 = $stripe->process(100, ['card_token' => 'tok_visa']);
print_r($result1);

echo "\n=== Платеж через PayPal ===\n";
$paypal = new PayPalPayment('client_id', 'client_secret');
$result2 = $paypal->process(100, ['payer_email' => 'user@example.com']);
print_r($result2);

echo "\n=== Платеж через Робокассу ===\n";
$robokassa = new RobokassaPayment('merchant_123', 'secret_key');
$result3 = $robokassa->process(5000, []);
print_r($result3);
```

---

## Антипаттерны ООП: Чего избегать

### 1. God Object (Божественный объект)

**Плохо:**
```php
class Application {
    public function connectDatabase() { }
    public function sendEmail() { }
    public function processPayment() { }
    public function generateReport() { }
    public function uploadFile() { }
    public function resizeImage() { }
    public function sendSMS() { }
    // ... еще 50 методов
}
```

**Хорошо:**
```php
class Database { }
class Mailer { }
class PaymentProcessor { }
class ReportGenerator { }
class FileUploader { }
class ImageProcessor { }
class SMSService { }

class Application {
    private Database $db;
    private Mailer $mailer;
    private PaymentProcessor $payments;
    // ... композиция вместо одного большого класса
}
```

### 2. Нарушение инкапсуляции

**Плохо:**
```php
class User {
    public $password; // Публичный пароль!
    public $balance;  // Публичный баланс!
}

$user = new User();
$user->balance = 1000000; // Можно изменить как угодно
```

**Хорошо:**
```php
class User {
    private string $passwordHash;
    private float $balance;

    public function setPassword(string $password): void {
        $this->passwordHash = password_hash($password, PASSWORD_BCRYPT);
    }

    public function addFunds(float $amount): void {
        if ($amount > 0) {
            $this->balance += $amount;
        }
    }

    public function getBalance(): float {
        return $this->balance;
    }
}
```

### 3. Чрезмерное наследование

**Плохо:**
```php
class Animal { }
class Mammal extends Animal { }
class Carnivore extends Mammal { }
class Feline extends Carnivore { }
class Cat extends Feline { }
class PersianCat extends Cat { }
class LongHairPersianCat extends PersianCat { }
// Слишком глубокая иерархия!
```

**Хорошо:**
```php
class Animal { }

class Cat extends Animal {
    private Breed $breed;
    private FurType $furType;
    // Композиция вместо глубокого наследования
}
```

---

## Краткая шпаргалка

### Инкапсуляция
```php
// Скрываем данные, предоставляем методы
class BankAccount {
    private float $balance;

    public function deposit(float $amount) { }
    public function getBalance(): float { }
}
```

### Наследование
```php
// Базовый класс
abstract class Vehicle {
    abstract public function move();
}

// Наследник
class Car extends Vehicle {
    public function move() {
        echo "Еду по дороге";
    }
}
```

### Полиморфизм
```php
// Один интерфейс - разные реализации
interface Shape {
    public function calculateArea(): float;
}

class Circle implements Shape {
    public function calculateArea(): float {
        return pi() * $this->radius ** 2;
    }
}

class Rectangle implements Shape {
    public function calculateArea(): float {
        return $this->width * $this->height;
    }
}

// Полиморфное использование
function printArea(Shape $shape) {
    echo $shape->calculateArea();
}
```

### Абстракция
```php
// Абстрактный класс с общим интерфейсом
abstract class DataStorage {
    abstract public function save(string $key, $value): void;
    abstract public function load(string $key);

    // Общая логика для всех хранилищ
    public function exists(string $key): bool {
        return $this->load($key) !== null;
    }
}

class FileStorage extends DataStorage { }
class DatabaseStorage extends DataStorage { }
class RedisStorage extends DataStorage { }
```

---

## Когда использовать ООП?

### ООП подходит для:

✅ **Больших и сложных приложений** - легче организовать код
✅ **Проектов с командной разработкой** - понятная структура
✅ **Приложений с много повторяющейся логикой** - переиспользование кода
✅ **Систем, требующих расширяемости** - легко добавлять новые функции
✅ **Enterprise-приложений** - стандартизированный подход

### ООП может быть избыточным для:

❌ **Простых скриптов** - процедурный код проще
❌ **Прототипов и MVP** - можно начать проще
❌ **Высоконагруженных систем** - ООП может добавлять overhead
❌ **Функциональных задач** - лучше подходит ФП

---

## Заключение

Четыре принципа ООП — это фундамент, на котором строится качественный, поддерживаемый и масштабируемый код:

1. **Инкапсуляция** — защищает данные и скрывает сложность
2. **Наследование** — позволяет переиспользовать код и создавать иерархии
3. **Полиморфизм** — обеспечивает гибкость через единый интерфейс
4. **Абстракция** — упрощает сложные системы через абстрактные контракты

**Ключевые выводы:**

- Используйте инкапсуляцию для защиты данных и контроля доступа
- Применяйте наследование разумно, избегайте глубоких иерархий
- Полиморфизм через интерфейсы лучше, чем через наследование
- Абстракция помогает думать о системе на высоком уровне
- Все принципы работают вместе для создания качественного кода

**Помните:** ООП — это не цель, а инструмент. Используйте его там, где он действительно упрощает задачу, а не усложняет её.

---

*Хотите углубиться в программирование? Читайте наши статьи о [программировании](/tags/программирование) и [архитектуре](/tags/архитектура).*
