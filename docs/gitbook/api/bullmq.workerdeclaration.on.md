<!-- Do not edit this file. It is automatically generated by API Documenter. -->

[Home](./index.md) &gt; [bullmq](./bullmq.md) &gt; [WorkerDeclaration](./bullmq.workerdeclaration.md) &gt; [on](./bullmq.workerdeclaration.on.md)

## WorkerDeclaration.on() method

Listen to 'active' event.

This event is triggered when a job enters the 'active' state.

<b>Signature:</b>

```typescript
on(event: 'active', listener: (job: Job, prev: string) => void): this;
```

## Parameters

|  Parameter | Type | Description |
|  --- | --- | --- |
|  event | 'active' |  |
|  listener | (job: [Job](./bullmq.job.md)<!-- -->, prev: string) =&gt; void |  |

<b>Returns:</b>

this

