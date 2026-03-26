/*
 * bsd_queue.h - BSD Queue macros (subset needed for mii)
 * 
 * Based on FreeBSD sys/queue.h
 * Simplified for FRANK Apple RP2350 port
 */
#ifndef BSD_QUEUE_H_
#define BSD_QUEUE_H_

/*
 * Singly-linked list
 */
#define SLIST_HEAD(name, type)                                          \
struct name {                                                           \
    struct type *slh_first;                                             \
}

#define SLIST_HEAD_INITIALIZER(head)                                    \
    { NULL }

#define SLIST_ENTRY(type)                                               \
struct {                                                                \
    struct type *sle_next;                                              \
}

#define SLIST_FIRST(head)       ((head)->slh_first)
#define SLIST_END(head)         NULL
#define SLIST_EMPTY(head)       (SLIST_FIRST(head) == SLIST_END(head))
#define SLIST_NEXT(elm, field)  ((elm)->field.sle_next)

#define SLIST_FOREACH(var, head, field)                                 \
    for((var) = SLIST_FIRST(head);                                      \
        (var) != SLIST_END(head);                                       \
        (var) = SLIST_NEXT(var, field))

#define SLIST_INIT(head) do {                                           \
    SLIST_FIRST(head) = SLIST_END(head);                                \
} while (0)

#define SLIST_INSERT_HEAD(head, elm, field) do {                        \
    (elm)->field.sle_next = (head)->slh_first;                          \
    (head)->slh_first = (elm);                                          \
} while (0)

#define SLIST_INSERT_AFTER(slistelm, elm, field) do {                   \
    (elm)->field.sle_next = (slistelm)->field.sle_next;                 \
    (slistelm)->field.sle_next = (elm);                                 \
} while (0)

#define SLIST_REMOVE_HEAD(head, field) do {                             \
    (head)->slh_first = (head)->slh_first->field.sle_next;              \
} while (0)

/*
 * Tail queue
 */
#define TAILQ_HEAD(name, type)                                          \
struct name {                                                           \
    struct type *tqh_first;                                             \
    struct type **tqh_last;                                             \
}

#define TAILQ_HEAD_INITIALIZER(head)                                    \
    { NULL, &(head).tqh_first }

#define TAILQ_ENTRY(type)                                               \
struct {                                                                \
    struct type *tqe_next;                                              \
    struct type **tqe_prev;                                             \
}

#define TAILQ_FIRST(head)       ((head)->tqh_first)
#define TAILQ_END(head)         NULL
#define TAILQ_NEXT(elm, field)  ((elm)->field.tqe_next)
#define TAILQ_LAST(head, headname) \
    (*(((struct headname *)((head)->tqh_last))->tqh_last))
#define TAILQ_PREV(elm, headname, field) \
    (*(((struct headname *)((elm)->field.tqe_prev))->tqh_last))
#define TAILQ_EMPTY(head)       (TAILQ_FIRST(head) == TAILQ_END(head))

#define TAILQ_FOREACH(var, head, field)                                 \
    for ((var) = TAILQ_FIRST(head);                                     \
         (var) != TAILQ_END(head);                                      \
         (var) = TAILQ_NEXT(var, field))

#define TAILQ_INIT(head) do {                                           \
    (head)->tqh_first = NULL;                                           \
    (head)->tqh_last = &(head)->tqh_first;                              \
} while (0)

#define TAILQ_INSERT_HEAD(head, elm, field) do {                        \
    if (((elm)->field.tqe_next = (head)->tqh_first) != NULL)            \
        (head)->tqh_first->field.tqe_prev = &(elm)->field.tqe_next;     \
    else                                                                \
        (head)->tqh_last = &(elm)->field.tqe_next;                      \
    (head)->tqh_first = (elm);                                          \
    (elm)->field.tqe_prev = &(head)->tqh_first;                         \
} while (0)

#define TAILQ_INSERT_TAIL(head, elm, field) do {                        \
    (elm)->field.tqe_next = NULL;                                       \
    (elm)->field.tqe_prev = (head)->tqh_last;                           \
    *(head)->tqh_last = (elm);                                          \
    (head)->tqh_last = &(elm)->field.tqe_next;                          \
} while (0)

#define TAILQ_REMOVE(head, elm, field) do {                             \
    if ((elm)->field.tqe_next != NULL)                                  \
        (elm)->field.tqe_next->field.tqe_prev = (elm)->field.tqe_prev;  \
    else                                                                \
        (head)->tqh_last = (elm)->field.tqe_prev;                       \
    *(elm)->field.tqe_prev = (elm)->field.tqe_next;                     \
} while (0)

#endif // BSD_QUEUE_H_
