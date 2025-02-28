<!-- Do not edit this file. It is automatically generated by API Documenter. -->

[Home](./index.md) &gt; [bullmq](./bullmq.md) &gt; [QueueEventsDeclaration](./bullmq.queueeventsdeclaration.md) &gt; [on](./bullmq.queueeventsdeclaration.on_7.md)

## QueueEventsDeclaration.on() method

Listen to 'stalled' event.

This event is triggered when a job has been moved from 'active' back to 'waiting'/'failed' due to the processor not being able to renew the lock on the said job.

<b>Signature:</b>

```typescript
on(event: 'stalled', listener: (args: {
        jobId: string;
    }, id: string) => void): this;
```

## Parameters

|  Parameter | Type | Description |
|  --- | --- | --- |
|  event | 'stalled' |  listener |
|  listener | (args: { jobId: string; }, id: string) =&gt; void |  |

<b>Returns:</b>

this

