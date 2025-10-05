---
title: "Anti-Corruption Layer: Защита от устаревших систем"
description: "Изучаем паттерн Anti-Corruption Layer: как защитить чистую архитектуру от устаревших систем с примерами на Go и PHP"
date: 2025-10-04
tldr: "Anti-Corruption Layer - архитектурный паттерн для интеграции с устаревшими системами без загрязнения собственной модели"
draft: false
tags: ["архитектура", "ddd", "go", "php", "паттерны", "интеграция", "legacy-системы"]
toc: true
---

# Anti-Corruption Layer: Защита от устаревших систем

Anti-Corruption Layer (ACL) — это архитектурный паттерн из Domain-Driven Design (DDD), который создает изолирующий слой между вашей чистой доменной моделью и внешними системами с несовместимыми моделями данных. Этот паттерн особенно важен при интеграции с устаревшими (legacy) системами или внешними API.

## Что такое Anti-Corruption Layer?

**Anti-Corruption Layer** — это адаптер между двумя подсистемами, который не позволяет концепциям одной системы "загрязнить" модель другой системы. ACL переводит запросы и ответы между различными моделями данных, обеспечивая изоляцию доменной логики.

{{< note >}}
Термин "corruption" здесь означает не повреждение данных, а концептуальное загрязнение одной модели понятиями из другой модели.
{{< /note >}}

### Основные функции ACL

1. **Трансляция моделей** — преобразование данных между различными представлениями
2. **Изоляция интерфейсов** — скрытие сложности внешних систем
3. **Адаптация протоколов** — работа с различными способами коммуникации
4. **Обработка ошибок** — унификация обработки исключительных ситуаций

## Когда использовать ACL?

### Сценарии применения

- **Интеграция с legacy-системами** с устаревшими моделями данных
- **Подключение внешних API** с неидеальным дизайном
- **Миграция между системами** с сохранением обратной совместимости
- **Интеграция между bounded contexts** в DDD

### Признаки необходимости ACL

```go
// ❌ Плохо - legacy модель загрязняет домен
type User struct {
    UserID          string    // Наша модель
    Name            string    // Наша модель
    LegacyUserCode  string    // Загрязнение от legacy системы
    LegacyStatus    int       // Загрязнение от legacy системы
    LegacyCreatedAt string    // Загрязнение от legacy системы (строка вместо time.Time)
}

// ✅ Хорошо - чистая доменная модель
type User struct {
    ID        UserID
    Name      string
    Status    UserStatus
    CreatedAt time.Time
}
```

## Структура Anti-Corruption Layer

### Компоненты ACL

1. **Domain Model** — чистая модель вашего домена
2. **External Model** — модель внешней системы
3. **Translator/Adapter** — преобразователь между моделями
4. **ACL Interface** — интерфейс для работы с внешней системой

```go
// Архитектура ACL в Go
package acl

// Доменная модель
type Order struct {
    ID          OrderID
    CustomerID  CustomerID
    Items       []OrderItem
    Status      OrderStatus
    CreatedAt   time.Time
    TotalAmount Money
}

// Внешняя модель (legacy система)
type LegacyOrder struct {
    OrderNum     string  `json:"order_num"`
    CustCode     string  `json:"cust_code"`
    OrderItems   string  `json:"order_items"`  // JSON строка
    OrderStat    int     `json:"order_stat"`
    CreateDate   string  `json:"create_date"`  // "YYYY-MM-DD"
    TotalCents   int     `json:"total_cents"`
}
```

## Реализация ACL на Go

### Базовая структура

```go
package orderacl

import (
    "encoding/json"
    "fmt"
    "strconv"
    "time"

    "github.com/myapp/domain/order"
)

// ACL интерфейс
type OrderACL interface {
    GetOrder(orderID string) (*order.Order, error)
    CreateOrder(order *order.Order) error
    UpdateOrderStatus(orderID string, status order.Status) error
}

// Реализация ACL
type LegacyOrderACL struct {
    legacyClient LegacyOrderClient
    translator   *OrderTranslator
}

func NewLegacyOrderACL(client LegacyOrderClient) OrderACL {
    return &LegacyOrderACL{
        legacyClient: client,
        translator:   NewOrderTranslator(),
    }
}
```

### Translator (Переводчик)

```go
// Translator для преобразования между моделями
type OrderTranslator struct{}

func NewOrderTranslator() *OrderTranslator {
    return &OrderTranslator{}
}

// Из legacy модели в доменную модель
func (t *OrderTranslator) ToDomain(legacyOrder *LegacyOrder) (*order.Order, error) {
    // Преобразование ID
    orderID, err := order.NewOrderID(legacyOrder.OrderNum)
    if err != nil {
        return nil, fmt.Errorf("invalid order ID: %w", err)
    }

    // Преобразование статуса
    status, err := t.convertStatus(legacyOrder.OrderStat)
    if err != nil {
        return nil, fmt.Errorf("invalid status: %w", err)
    }

    // Преобразование даты
    createdAt, err := time.Parse("2006-01-02", legacyOrder.CreateDate)
    if err != nil {
        return nil, fmt.Errorf("invalid date format: %w", err)
    }

    // Преобразование товаров
    items, err := t.convertItems(legacyOrder.OrderItems)
    if err != nil {
        return nil, fmt.Errorf("failed to convert items: %w", err)
    }

    // Преобразование суммы
    totalAmount := order.NewMoney(legacyOrder.TotalCents, "RUB")

    return &order.Order{
        ID:          orderID,
        CustomerID:  order.NewCustomerID(legacyOrder.CustCode),
        Items:       items,
        Status:      status,
        CreatedAt:   createdAt,
        TotalAmount: totalAmount,
    }, nil
}

// Из доменной модели в legacy модель
func (t *OrderTranslator) ToLegacy(domainOrder *order.Order) (*LegacyOrder, error) {
    // Сериализация товаров в JSON
    itemsJSON, err := json.Marshal(domainOrder.Items)
    if err != nil {
        return nil, fmt.Errorf("failed to serialize items: %w", err)
    }

    return &LegacyOrder{
        OrderNum:   domainOrder.ID.String(),
        CustCode:   domainOrder.CustomerID.String(),
        OrderItems: string(itemsJSON),
        OrderStat:  t.convertStatusToLegacy(domainOrder.Status),
        CreateDate: domainOrder.CreatedAt.Format("2006-01-02"),
        TotalCents: domainOrder.TotalAmount.Cents(),
    }, nil
}

// Вспомогательные методы преобразования
func (t *OrderTranslator) convertStatus(legacyStatus int) (order.Status, error) {
    switch legacyStatus {
    case 0:
        return order.StatusPending, nil
    case 1:
        return order.StatusConfirmed, nil
    case 2:
        return order.StatusShipped, nil
    case 3:
        return order.StatusDelivered, nil
    case 9:
        return order.StatusCancelled, nil
    default:
        return "", fmt.Errorf("unknown legacy status: %d", legacyStatus)
    }
}

func (t *OrderTranslator) convertStatusToLegacy(status order.Status) int {
    switch status {
    case order.StatusPending:
        return 0
    case order.StatusConfirmed:
        return 1
    case order.StatusShipped:
        return 2
    case order.StatusDelivered:
        return 3
    case order.StatusCancelled:
        return 9
    default:
        return 0
    }
}

func (t *OrderTranslator) convertItems(itemsJSON string) ([]order.Item, error) {
    var legacyItems []struct {
        ProductCode string `json:"product_code"`
        Qty         int    `json:"qty"`
        PriceCents  int    `json:"price_cents"`
    }

    if err := json.Unmarshal([]byte(itemsJSON), &legacyItems); err != nil {
        return nil, err
    }

    items := make([]order.Item, len(legacyItems))
    for i, legacyItem := range legacyItems {
        items[i] = order.Item{
            ProductID: order.NewProductID(legacyItem.ProductCode),
            Quantity:  legacyItem.Qty,
            Price:     order.NewMoney(legacyItem.PriceCents, "RUB"),
        }
    }

    return items, nil
}
```

### Реализация ACL методов

```go
// Получение заказа
func (acl *LegacyOrderACL) GetOrder(orderID string) (*order.Order, error) {
    // Вызов legacy API
    legacyOrder, err := acl.legacyClient.GetOrder(orderID)
    if err != nil {
        return nil, fmt.Errorf("failed to get legacy order: %w", err)
    }

    // Преобразование в доменную модель
    domainOrder, err := acl.translator.ToDomain(legacyOrder)
    if err != nil {
        return nil, fmt.Errorf("failed to translate order: %w", err)
    }

    return domainOrder, nil
}

// Создание заказа
func (acl *LegacyOrderACL) CreateOrder(domainOrder *order.Order) error {
    // Преобразование в legacy модель
    legacyOrder, err := acl.translator.ToLegacy(domainOrder)
    if err != nil {
        return fmt.Errorf("failed to translate order: %w", err)
    }

    // Вызов legacy API
    if err := acl.legacyClient.CreateOrder(legacyOrder); err != nil {
        return fmt.Errorf("failed to create legacy order: %w", err)
    }

    return nil
}

// Обновление статуса
func (acl *LegacyOrderACL) UpdateOrderStatus(orderID string, status order.Status) error {
    // Преобразование статуса
    legacyStatus := acl.translator.convertStatusToLegacy(status)

    // Вызов legacy API
    if err := acl.legacyClient.UpdateOrderStatus(orderID, legacyStatus); err != nil {
        return fmt.Errorf("failed to update legacy order status: %w", err)
    }

    return nil
}
```

### Legacy Client

```go
// Клиент для работы с legacy системой
type LegacyOrderClient interface {
    GetOrder(orderNum string) (*LegacyOrder, error)
    CreateOrder(order *LegacyOrder) error
    UpdateOrderStatus(orderNum string, status int) error
}

type HTTPLegacyClient struct {
    baseURL string
    client  *http.Client
}

func NewHTTPLegacyClient(baseURL string) LegacyOrderClient {
    return &HTTPLegacyClient{
        baseURL: baseURL,
        client:  &http.Client{Timeout: 30 * time.Second},
    }
}

func (c *HTTPLegacyClient) GetOrder(orderNum string) (*LegacyOrder, error) {
    url := fmt.Sprintf("%s/api/orders/%s", c.baseURL, orderNum)

    resp, err := c.client.Get(url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("legacy API returned status: %d", resp.StatusCode)
    }

    var legacyOrder LegacyOrder
    if err := json.NewDecoder(resp.Body).Decode(&legacyOrder); err != nil {
        return nil, err
    }

    return &legacyOrder, nil
}
```

## Реализация ACL на PHP

### Структура классов

```php
<?php

namespace App\ACL\Order;

use App\Domain\Order\Order;
use App\Domain\Order\OrderId;
use App\Domain\Order\Status;
use DateTimeImmutable;

// ACL интерфейс
interface OrderACLInterface
{
    public function getOrder(string $orderId): ?Order;
    public function createOrder(Order $order): void;
    public function updateOrderStatus(string $orderId, Status $status): void;
}

// Реализация ACL
class LegacyOrderACL implements OrderACLInterface
{
    private LegacyOrderClient $legacyClient;
    private OrderTranslator $translator;

    public function __construct(
        LegacyOrderClient $legacyClient,
        OrderTranslator $translator
    ) {
        $this->legacyClient = $legacyClient;
        $this->translator = $translator;
    }

    public function getOrder(string $orderId): ?Order
    {
        try {
            // Получаем данные из legacy системы
            $legacyOrder = $this->legacyClient->getOrder($orderId);

            if ($legacyOrder === null) {
                return null;
            }

            // Преобразуем в доменную модель
            return $this->translator->toDomain($legacyOrder);

        } catch (Exception $e) {
            throw new ACLException("Failed to get order: " . $e->getMessage(), 0, $e);
        }
    }

    public function createOrder(Order $order): void
    {
        try {
            // Преобразуем в legacy модель
            $legacyOrder = $this->translator->toLegacy($order);

            // Создаем в legacy системе
            $this->legacyClient->createOrder($legacyOrder);

        } catch (Exception $e) {
            throw new ACLException("Failed to create order: " . $e->getMessage(), 0, $e);
        }
    }

    public function updateOrderStatus(string $orderId, Status $status): void
    {
        try {
            // Преобразуем статус
            $legacyStatus = $this->translator->statusToLegacy($status);

            // Обновляем в legacy системе
            $this->legacyClient->updateOrderStatus($orderId, $legacyStatus);

        } catch (Exception $e) {
            throw new ACLException("Failed to update order status: " . $e->getMessage(), 0, $e);
        }
    }
}
```

### Legacy модель

```php
<?php

namespace App\ACL\Order;

// Legacy модель данных
class LegacyOrder
{
    public string $orderNum;
    public string $custCode;
    public string $orderItems; // JSON строка
    public int $orderStat;
    public string $createDate; // YYYY-MM-DD
    public int $totalCents;

    public function __construct(
        string $orderNum,
        string $custCode,
        string $orderItems,
        int $orderStat,
        string $createDate,
        int $totalCents
    ) {
        $this->orderNum = $orderNum;
        $this->custCode = $custCode;
        $this->orderItems = $orderItems;
        $this->orderStat = $orderStat;
        $this->createDate = $createDate;
        $this->totalCents = $totalCents;
    }

    public function toArray(): array
    {
        return [
            'order_num' => $this->orderNum,
            'cust_code' => $this->custCode,
            'order_items' => $this->orderItems,
            'order_stat' => $this->orderStat,
            'create_date' => $this->createDate,
            'total_cents' => $this->totalCents,
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            $data['order_num'],
            $data['cust_code'],
            $data['order_items'],
            $data['order_stat'],
            $data['create_date'],
            $data['total_cents']
        );
    }
}
```

### Translator на PHP

```php
<?php

namespace App\ACL\Order;

use App\Domain\Order\Order;
use App\Domain\Order\OrderId;
use App\Domain\Order\CustomerId;
use App\Domain\Order\Status;
use App\Domain\Order\OrderItem;
use App\Domain\Order\ProductId;
use App\Domain\Order\Money;
use DateTimeImmutable;
use InvalidArgumentException;

class OrderTranslator
{
    // Из legacy в доменную модель
    public function toDomain(LegacyOrder $legacyOrder): Order
    {
        return new Order(
            new OrderId($legacyOrder->orderNum),
            new CustomerId($legacyOrder->custCode),
            $this->convertItems($legacyOrder->orderItems),
            $this->convertStatus($legacyOrder->orderStat),
            DateTimeImmutable::createFromFormat('Y-m-d', $legacyOrder->createDate),
            new Money($legacyOrder->totalCents, 'RUB')
        );
    }

    // Из доменной модели в legacy
    public function toLegacy(Order $order): LegacyOrder
    {
        return new LegacyOrder(
            $order->getId()->value(),
            $order->getCustomerId()->value(),
            $this->serializeItems($order->getItems()),
            $this->statusToLegacy($order->getStatus()),
            $order->getCreatedAt()->format('Y-m-d'),
            $order->getTotalAmount()->getCents()
        );
    }

    // Преобразование статуса из legacy
    private function convertStatus(int $legacyStatus): Status
    {
        return match($legacyStatus) {
            0 => Status::PENDING,
            1 => Status::CONFIRMED,
            2 => Status::SHIPPED,
            3 => Status::DELIVERED,
            9 => Status::CANCELLED,
            default => throw new InvalidArgumentException("Unknown legacy status: $legacyStatus")
        };
    }

    // Преобразование статуса в legacy
    public function statusToLegacy(Status $status): int
    {
        return match($status) {
            Status::PENDING => 0,
            Status::CONFIRMED => 1,
            Status::SHIPPED => 2,
            Status::DELIVERED => 3,
            Status::CANCELLED => 9,
        };
    }

    // Преобразование товаров из JSON
    private function convertItems(string $itemsJson): array
    {
        $legacyItems = json_decode($itemsJson, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new InvalidArgumentException('Invalid items JSON: ' . json_last_error_msg());
        }

        return array_map(function($item) {
            return new OrderItem(
                new ProductId($item['product_code']),
                $item['qty'],
                new Money($item['price_cents'], 'RUB')
            );
        }, $legacyItems);
    }

    // Сериализация товаров в JSON
    private function serializeItems(array $items): string
    {
        $legacyItems = array_map(function(OrderItem $item) {
            return [
                'product_code' => $item->getProductId()->value(),
                'qty' => $item->getQuantity(),
                'price_cents' => $item->getPrice()->getCents()
            ];
        }, $items);

        return json_encode($legacyItems);
    }
}
```

### Legacy Client на PHP

```php
<?php

namespace App\ACL\Order;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;

interface LegacyOrderClient
{
    public function getOrder(string $orderNum): ?LegacyOrder;
    public function createOrder(LegacyOrder $order): void;
    public function updateOrderStatus(string $orderNum, int $status): void;
}

class HttpLegacyOrderClient implements LegacyOrderClient
{
    private Client $httpClient;
    private string $baseUrl;

    public function __construct(string $baseUrl)
    {
        $this->baseUrl = rtrim($baseUrl, '/');
        $this->httpClient = new Client([
            'timeout' => 30,
            'headers' => [
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
            ]
        ]);
    }

    public function getOrder(string $orderNum): ?LegacyOrder
    {
        try {
            $response = $this->httpClient->get(
                "{$this->baseUrl}/api/orders/{$orderNum}"
            );

            if ($response->getStatusCode() === 404) {
                return null;
            }

            $data = json_decode($response->getBody()->getContents(), true);
            return LegacyOrder::fromArray($data);

        } catch (GuzzleException $e) {
            throw new LegacyClientException("Failed to get order: " . $e->getMessage(), 0, $e);
        }
    }

    public function createOrder(LegacyOrder $order): void
    {
        try {
            $response = $this->httpClient->post(
                "{$this->baseUrl}/api/orders",
                ['json' => $order->toArray()]
            );

            if ($response->getStatusCode() >= 400) {
                throw new LegacyClientException("Legacy API returned status: " . $response->getStatusCode());
            }

        } catch (GuzzleException $e) {
            throw new LegacyClientException("Failed to create order: " . $e->getMessage(), 0, $e);
        }
    }

    public function updateOrderStatus(string $orderNum, int $status): void
    {
        try {
            $response = $this->httpClient->patch(
                "{$this->baseUrl}/api/orders/{$orderNum}/status",
                ['json' => ['status' => $status]]
            );

            if ($response->getStatusCode() >= 400) {
                throw new LegacyClientException("Legacy API returned status: " . $response->getStatusCode());
            }

        } catch (GuzzleException $e) {
            throw new LegacyClientException("Failed to update order status: " . $e->getMessage(), 0, $e);
        }
    }
}
```

## Тестирование ACL

### Unit тесты для Go

```go
package orderacl_test

import (
    "testing"
    "time"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"

    "github.com/myapp/acl/orderacl"
    "github.com/myapp/domain/order"
)

// Mock для legacy client
type MockLegacyClient struct {
    mock.Mock
}

func (m *MockLegacyClient) GetOrder(orderNum string) (*orderacl.LegacyOrder, error) {
    args := m.Called(orderNum)
    return args.Get(0).(*orderacl.LegacyOrder), args.Error(1)
}

func (m *MockLegacyClient) CreateOrder(order *orderacl.LegacyOrder) error {
    args := m.Called(order)
    return args.Error(0)
}

func (m *MockLegacyClient) UpdateOrderStatus(orderNum string, status int) error {
    args := m.Called(orderNum, status)
    return args.Error(0)
}

func TestOrderACL_GetOrder(t *testing.T) {
    // Arrange
    mockClient := new(MockLegacyClient)
    acl := orderacl.NewLegacyOrderACL(mockClient)

    legacyOrder := &orderacl.LegacyOrder{
        OrderNum:   "ORDER-123",
        CustCode:   "CUST-456",
        OrderItems: `[{"product_code":"PROD-001","qty":2,"price_cents":1500}]`,
        OrderStat:  1,
        CreateDate: "2025-01-13",
        TotalCents: 3000,
    }

    mockClient.On("GetOrder", "ORDER-123").Return(legacyOrder, nil)

    // Act
    result, err := acl.GetOrder("ORDER-123")

    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, result)
    assert.Equal(t, "ORDER-123", result.ID.String())
    assert.Equal(t, "CUST-456", result.CustomerID.String())
    assert.Equal(t, order.StatusConfirmed, result.Status)
    assert.Equal(t, 3000, result.TotalAmount.Cents())

    mockClient.AssertExpectations(t)
}
```

### Unit тесты для PHP

```php
<?php

namespace Tests\Unit\ACL\Order;

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\MockObject\MockObject;
use App\ACL\Order\LegacyOrderACL;
use App\ACL\Order\LegacyOrderClient;
use App\ACL\Order\OrderTranslator;
use App\ACL\Order\LegacyOrder;
use App\Domain\Order\Order;
use App\Domain\Order\Status;

class LegacyOrderACLTest extends TestCase
{
    private MockObject $mockClient;
    private OrderTranslator $translator;
    private LegacyOrderACL $acl;

    protected function setUp(): void
    {
        $this->mockClient = $this->createMock(LegacyOrderClient::class);
        $this->translator = new OrderTranslator();
        $this->acl = new LegacyOrderACL($this->mockClient, $this->translator);
    }

    public function testGetOrder(): void
    {
        // Arrange
        $legacyOrder = new LegacyOrder(
            'ORDER-123',
            'CUST-456',
            '[{"product_code":"PROD-001","qty":2,"price_cents":1500}]',
            1,
            '2025-01-13',
            3000
        );

        $this->mockClient
            ->expects($this->once())
            ->method('getOrder')
            ->with('ORDER-123')
            ->willReturn($legacyOrder);

        // Act
        $result = $this->acl->getOrder('ORDER-123');

        // Assert
        $this->assertInstanceOf(Order::class, $result);
        $this->assertEquals('ORDER-123', $result->getId()->value());
        $this->assertEquals('CUST-456', $result->getCustomerId()->value());
        $this->assertEquals(Status::CONFIRMED, $result->getStatus());
        $this->assertEquals(3000, $result->getTotalAmount()->getCents());
    }

    public function testCreateOrder(): void
    {
        // Arrange
        $order = $this->createTestOrder();

        $this->mockClient
            ->expects($this->once())
            ->method('createOrder')
            ->with($this->callback(function(LegacyOrder $legacyOrder) {
                return $legacyOrder->orderNum === 'ORDER-123' &&
                       $legacyOrder->orderStat === 1;
            }));

        // Act & Assert
        $this->acl->createOrder($order);
    }
}
```

## Лучшие практики

### 1. Четкое разделение моделей

```go
// ❌ Плохо - смешивание моделей
type User struct {
    // Доменные поля
    ID   UserID
    Name string

    // Legacy поля - НЕ ДЕЛАЙТЕ ТАК!
    LegacyUserCode string `json:"legacy_user_code"`
    LegacyStatus   int    `json:"legacy_status"`
}

// ✅ Хорошо - четкое разделение
// Доменная модель
type User struct {
    ID     UserID
    Name   string
    Status UserStatus
}

// Legacy модель (только в ACL)
type LegacyUser struct {
    UserCode string `json:"user_code"`
    UserName string `json:"user_name"`
    Status   int    `json:"status"`
}
```

### 2. Обработка ошибок трансляции

```php
<?php

class OrderTranslator
{
    public function toDomain(LegacyOrder $legacyOrder): Order
    {
        try {
            return new Order(
                new OrderId($legacyOrder->orderNum),
                new CustomerId($legacyOrder->custCode),
                $this->convertItems($legacyOrder->orderItems),
                $this->convertStatus($legacyOrder->orderStat),
                DateTimeImmutable::createFromFormat('Y-m-d', $legacyOrder->createDate),
                new Money($legacyOrder->totalCents, 'RUB')
            );
        } catch (Exception $e) {
            throw new TranslationException("Failed to translate legacy order: " . $e->getMessage(), 0, $e);
        }
    }
}
```

### 3. Кэширование и производительность

```go
// Кэширование переводов для часто используемых данных
type CachedOrderTranslator struct {
    translator *OrderTranslator
    cache      map[string]*order.Order
    mutex      sync.RWMutex
    ttl        time.Duration
}

func (t *CachedOrderTranslator) ToDomain(legacyOrder *LegacyOrder) (*order.Order, error) {
    cacheKey := legacyOrder.OrderNum + "_" + fmt.Sprint(legacyOrder.OrderStat)

    t.mutex.RLock()
    if cached, exists := t.cache[cacheKey]; exists {
        t.mutex.RUnlock()
        return cached, nil
    }
    t.mutex.RUnlock()

    // Переводим и кэшируем
    domainOrder, err := t.translator.ToDomain(legacyOrder)
    if err != nil {
        return nil, err
    }

    t.mutex.Lock()
    t.cache[cacheKey] = domainOrder
    t.mutex.Unlock()

    return domainOrder, nil
}
```

### 4. Версионирование ACL

```php
<?php

interface VersionedACL
{
    public function getVersion(): string;
    public function supportsLegacyVersion(string $version): bool;
}

class OrderACLV1 implements OrderACLInterface, VersionedACL
{
    public function getVersion(): string
    {
        return '1.0';
    }

    public function supportsLegacyVersion(string $version): bool
    {
        return in_array($version, ['1.0', '1.1']);
    }
}

class OrderACLV2 implements OrderACLInterface, VersionedACL
{
    public function getVersion(): string
    {
        return '2.0';
    }

    public function supportsLegacyVersion(string $version): bool
    {
        return version_compare($version, '2.0', '>=');
    }
}
```

### 5. Мониторинг ACL

```go
// Метрики для ACL
type ACLMetrics struct {
    translationErrors    prometheus.Counter
    translationDuration  prometheus.Histogram
    legacyAPIErrors      prometheus.Counter
    cacheHits           prometheus.Counter
    cacheMisses         prometheus.Counter
}

func (acl *LegacyOrderACL) GetOrderWithMetrics(orderID string) (*order.Order, error) {
    start := time.Now()
    defer func() {
        acl.metrics.translationDuration.Observe(time.Since(start).Seconds())
    }()

    // Проверяем кэш
    if cached := acl.getFromCache(orderID); cached != nil {
        acl.metrics.cacheHits.Inc()
        return cached, nil
    }
    acl.metrics.cacheMisses.Inc()

    // Получаем из legacy системы
    legacyOrder, err := acl.legacyClient.GetOrder(orderID)
    if err != nil {
        acl.metrics.legacyAPIErrors.Inc()
        return nil, err
    }

    // Переводим
    domainOrder, err := acl.translator.ToDomain(legacyOrder)
    if err != nil {
        acl.metrics.translationErrors.Inc()
        return nil, err
    }

    // Кэшируем и возвращаем
    acl.putToCache(orderID, domainOrder)
    return domainOrder, nil
}
```

## Паттерны интеграции с ACL

### 1. Facade Pattern + ACL

```go
// Фасад, скрывающий сложность ACL
type OrderFacade struct {
    orderACL     OrderACL
    paymentACL   PaymentACL
    inventoryACL InventoryACL
}

func (f *OrderFacade) ProcessOrder(orderRequest *CreateOrderRequest) (*order.Order, error) {
    // Создаем заказ через ACL
    newOrder, err := f.orderACL.CreateOrder(orderRequest.ToOrder())
    if err != nil {
        return nil, err
    }

    // Обрабатываем платеж через отдельный ACL
    payment, err := f.paymentACL.ProcessPayment(&PaymentRequest{
        OrderID: newOrder.ID,
        Amount:  newOrder.TotalAmount,
    })
    if err != nil {
        // Откатываем заказ
        f.orderACL.CancelOrder(newOrder.ID)
        return nil, err
    }

    // Резервируем товары через третий ACL
    if err := f.inventoryACL.ReserveItems(newOrder.Items); err != nil {
        f.paymentACL.RefundPayment(payment.ID)
        f.orderACL.CancelOrder(newOrder.ID)
        return nil, err
    }

    return newOrder, nil
}
```

### 2. Repository Pattern с ACL

```php
<?php

class OrderRepository
{
    private OrderACLInterface $orderACL;
    private CacheInterface $cache;

    public function __construct(OrderACLInterface $orderACL, CacheInterface $cache)
    {
        $this->orderACL = $orderACL;
        $this->cache = $cache;
    }

    public function findById(string $orderId): ?Order
    {
        // Проверяем локальный кэш
        $cacheKey = "order:$orderId";
        if ($cached = $this->cache->get($cacheKey)) {
            return $cached;
        }

        // Получаем через ACL
        $order = $this->orderACL->getOrder($orderId);

        if ($order !== null) {
            $this->cache->set($cacheKey, $order, 300); // 5 минут
        }

        return $order;
    }

    public function save(Order $order): void
    {
        // Сохраняем через ACL
        if ($order->getId()->value() === null) {
            $this->orderACL->createOrder($order);
        } else {
            $this->orderACL->updateOrder($order);
        }

        // Инвалидируем кэш
        $this->cache->delete("order:" . $order->getId()->value());
    }
}
```

## Сложные сценарии

### 1. Множественные legacy системы

```go
// ACL для работы с несколькими legacy системами
type CompositeOrderACL struct {
    primaryACL   OrderACL      // Основная система
    secondaryACL OrderACL      // Резервная система
    router       *ACLRouter    // Роутер запросов
}

func (c *CompositeOrderACL) GetOrder(orderID string) (*order.Order, error) {
    // Определяем, какую систему использовать
    aclToUse := c.router.RouteGetOrder(orderID)

    switch aclToUse {
    case "primary":
        order, err := c.primaryACL.GetOrder(orderID)
        if err != nil {
            // Fallback на вторичную систему
            return c.secondaryACL.GetOrder(orderID)
        }
        return order, nil

    case "secondary":
        return c.secondaryACL.GetOrder(orderID)

    default:
        return nil, fmt.Errorf("no suitable ACL found for order %s", orderID)
    }
}
```

### 2. Async ACL с очередями

```go
// Асинхронный ACL с очередями сообщений
type AsyncOrderACL struct {
    messageQueue MessageQueue
    translator   *OrderTranslator
    resultStore  ResultStore
}

func (a *AsyncOrderACL) CreateOrderAsync(order *order.Order, correlationID string) error {
    // Преобразуем в legacy модель
    legacyOrder, err := a.translator.ToLegacy(order)
    if err != nil {
        return err
    }

    // Отправляем в очередь
    message := &CreateOrderMessage{
        LegacyOrder:   legacyOrder,
        CorrelationID: correlationID,
        Timestamp:     time.Now(),
    }

    return a.messageQueue.Publish("legacy.order.create", message)
}

func (a *AsyncOrderACL) GetOrderResult(correlationID string) (*order.Order, error) {
    // Получаем результат из хранилища
    result, err := a.resultStore.Get(correlationID)
    if err != nil {
        return nil, err
    }

    if result.Status == "pending" {
        return nil, ErrOrderPending
    }

    if result.Status == "error" {
        return nil, fmt.Errorf("order creation failed: %s", result.Error)
    }

    return a.translator.ToDomain(result.LegacyOrder)
}
```

## Инструменты и библиотеки

### Go библиотеки

```go
// Использование Go библиотек для ACL
import (
    "github.com/mitchellh/mapstructure" // Для маппинга структур
    "github.com/go-playground/validator" // Для валидации
    "github.com/patrickmn/go-cache"     // Для кэширования
)

type ValidatedTranslator struct {
    validator *validator.Validate
    cache     *cache.Cache
}

func (t *ValidatedTranslator) ToDomainWithValidation(data map[string]interface{}) (*order.Order, error) {
    // Маппинг в legacy структуру
    var legacyOrder LegacyOrder
    if err := mapstructure.Decode(data, &legacyOrder); err != nil {
        return nil, err
    }

    // Валидация legacy данных
    if err := t.validator.Struct(&legacyOrder); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }

    // Кэшированный перевод
    cacheKey := fmt.Sprintf("order_%s", legacyOrder.OrderNum)
    if cached, found := t.cache.Get(cacheKey); found {
        return cached.(*order.Order), nil
    }

    // Обычный перевод
    domainOrder, err := t.ToDomain(&legacyOrder)
    if err != nil {
        return nil, err
    }

    // Кэшируем результат
    t.cache.Set(cacheKey, domainOrder, cache.DefaultExpiration)
    return domainOrder, nil
}
```

### PHP библиотеки

```php
<?php

use Symfony\Component\Serializer\Serializer;
use Symfony\Component\Serializer\Normalizer\ObjectNormalizer;
use Symfony\Component\Serializer\Encoder\JsonEncoder;
use Symfony\Component\Validator\Validator\ValidatorInterface;

class SerializerBasedTranslator
{
    private Serializer $serializer;
    private ValidatorInterface $validator;

    public function __construct(ValidatorInterface $validator)
    {
        $this->validator = $validator;
        $this->serializer = new Serializer(
            [new ObjectNormalizer()],
            [new JsonEncoder()]
        );
    }

    public function toDomainFromArray(array $legacyData): Order
    {
        // Десериализация в legacy объект
        $legacyOrder = $this->serializer->denormalize(
            $legacyData,
            LegacyOrder::class
        );

        // Валидация
        $violations = $this->validator->validate($legacyOrder);
        if (count($violations) > 0) {
            throw new ValidationException($violations);
        }

        // Перевод в доменную модель
        return $this->toDomain($legacyOrder);
    }
}
```

## Заключение

Anti-Corruption Layer — это критически важный паттерн для поддержания чистоты архитектуры при интеграции с внешними системами. Ключевые преимущества ACL:

### Преимущества
1. **Изоляция доменной модели** от внешних зависимостей
2. **Гибкость в изменениях** — изменения в legacy системе не влияют на домен
3. **Тестируемость** — легко мокать ACL для тестов
4. **Переиспользование** — один ACL может обслуживать несколько потребителей
5. **Эволюция системы** — постепенная замена legacy компонентов

### Рекомендации по применению

1. **Используйте ACL всегда** при интеграции с внешними системами
2. **Инвестируйте в качественные тесты** для translator'ов
3. **Мониторьте производительность** трансляций
4. **Планируйте версионирование** ACL заранее
5. **Документируйте маппинги** между моделями
6. **Рассматривайте кэширование** для часто используемых переводов

Anti-Corruption Layer помогает создавать устойчивую архитектуру, которая может развиваться независимо от ограничений устаревших систем. Инвестиции в качественную реализацию ACL окупаются снижением технического долга и повышением гибкости системы.

---

*Интересуют другие архитектурные паттерны? Читайте наши статьи о [Event-Driven Architecture](/posts/event-driven-architecture/) и [микросервисах](/tags/микросервисы).*
