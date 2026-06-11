import "@typespec/http";

using Http;

@service(#{ title: "Calendar Booking Service" })
namespace CalendarService;

/**
 * Владелец календаря.
 * Один заранее заданный профиль, используется по умолчанию в админской части.
 * Регистрация и авторизация в проекте отсутствуют.
 */
model Owner {
  /** Идентификатор владельца */
  id: int32;

  /** Имя владельца */
  name: string;

  /** Email владельца */
  @format("email")
  email: string;
}

/**
 * Тип события, создаваемый владельцем календаря.
 */
model EventType {
  /** Идентификатор типа события */
  id: int32;

  /** Название типа события */
  name: string;

  /** Описание типа события */
  description: string;

  /** Длительность события в минутах */
  @minValue(1)
  durationMinutes: int32;
}

/**
 * Данные для создания типа события (без идентификатора).
 */
model EventTypeCreate {
  /** Название типа события */
  name: string;

  /** Описание типа события */
  description: string;

  /** Длительность события в минутах */
  @minValue(1)
  durationMinutes: int32;
}

/**
 * Слот календаря (вычисляемый, не хранится отдельно).
 * Слоты формируются на 14 дней, начиная с текущей даты.
 * Длительность слота определяется выбранным типом события.
 */
model Slot {
  /** Время начала слота (UTC) */
  startTime: utcDateTime;

  /** Свободен ли слот. На одно и то же время нельзя создать две записи, даже если это разные типы событий */
  isAvailable: boolean;
}

/**
 * Бронирование, созданное гостем на свободный слот.
 */
model Booking {
  /** Идентификатор бронирования */
  id: int32;

  /** Идентификатор типа события */
  eventTypeId: int32;

  /** Время начала встречи (UTC) */
  startTime: utcDateTime;

  /** Имя гостя */
  guestName: string;

  /** Email гостя */
  @format("email")
  guestEmail: string;

  /** Комментарий гостя */
  comment?: string;

  /** Время создания бронирования (UTC) */
  createdAt: utcDateTime;
}

/**
 * Данные для создания бронирования гостем.
 * Гость бронирует слот без создания аккаунта и без входа в систему.
 */
model BookingCreate {
  /** Идентификатор типа события */
  eventTypeId: int32;

  /** Время начала встречи (UTC). Должно совпадать со свободным слотом в окне записи (14 дней от текущей даты) */
  startTime: utcDateTime;

  /** Имя гостя */
  guestName: string;

  /** Email гостя */
  @format("email")
  guestEmail: string;

  /** Комментарий гостя */
  comment?: string;
}

/** Ошибка API */
@error
model Error {
  /** Код ошибки */
  code: int32;

  /** Сообщение об ошибке */
  message: string;
}

/**
 * Публичный сценарий гостя:
 * 1. Смотрит страницу с видами брони (название, описание, длительность).
 * 2. Выбирает тип события и открывает календарь со свободными слотами на ближайшие 14 дней.
 * 3. Создаёт бронирование на выбранный свободный слот.
 */
@tag("Guest")
interface Public {
  /** Список типов событий: название, описание и длительность */
  @route("/event-types")
  @get
  listEventTypes(): EventType[];

  /** Получить тип события по идентификатору */
  @route("/event-types/{id}")
  @get
  getEventType(@path id: int32): EventType | Error;

  /**
   * Слоты для типа события на ближайшие 14 дней, начиная с текущей даты.
   * Гость может записаться только на свободный слот из этого окна.
   */
  @route("/event-types/{id}/slots")
  @get
  listSlots(@path id: int32): Slot[] | Error;

  /**
   * Создать бронирование на выбранный свободный слот.
   * На одно и то же время нельзя создать две записи, даже если это разные
   * типы событий — при конфликте возвращается ошибка 409.
   */
  @route("/bookings")
  @post
  createBooking(@body booking: BookingCreate): {
    @statusCode statusCode: 201;
    @body body: Booking;
  } | {
    @statusCode statusCode: 409;
    @body body: Error;
  } | Error;
}
