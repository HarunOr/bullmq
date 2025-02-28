<!-- Do not edit this file. It is automatically generated by API Documenter. -->

[Home](./index.md) &gt; [bullmq](./bullmq.md) &gt; [QueueGetters](./bullmq.queuegetters.md) &gt; [getJobCounts](./bullmq.queuegetters.getjobcounts.md)

## QueueGetters.getJobCounts() method

Returns the job counts for each type specified or every list/set in the queue by default.

<b>Signature:</b>

```typescript
getJobCounts(...types: string[]): Promise<{
        [index: string]: number;
    }>;
```

## Parameters

|  Parameter | Type | Description |
|  --- | --- | --- |
|  types | string\[\] |  |

<b>Returns:</b>

Promise&lt;{ \[index: string\]: number; }&gt;

An object, key (type) and value (count)

