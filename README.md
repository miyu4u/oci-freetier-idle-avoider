# OCI Free Tier Idle Avoider
## Introduction
At some point, Oracle Cloud implemented a policy that forcibly terminates instances that have been deemed idle. While it is unclear when this policy was put in place, the idle instance conditions are described in the following link:
https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm#compute__idleinstances

* CPU utilization for the 95th percentile is less than 10%
* Network utilization is less than 10%
* Memory utilization is less than 10% (applies to A1 shapes only)

I found a solution to this issue on Reddit in the form of a comment by user lvkaszus. The solution involves running a benchmark that prevents instances from being considered idle. I decided to adapt this solution to my Kubernetes setup, which runs on two different regions.

## How it Works
If the CPU utilization is less than 10% for 5% of the week, then it needs to be over 10% for 8.4 hours in order to prevent the instance from being considered idle. This can be easily achieved by running the benchmark for 2 hours per week during the early morning hours, when the instance is not being used.

I use my OCI Free Tier kube cluster as a personal homelab, and I run the benchmark during the early morning hours.

## Usage

* manifest/sysbench-execution-cronjob.yaml: When you only want to run the benchmark at specific times.
* manifest/sysbench-execution-daemonset.yaml: When you want to run the benchmark on the node continuously.
* manifest/sysbench-installation.yaml: Install sysbench on the target node (works only for Debian-based systems).

### Common

If you want to change the execution time, modify the command in the annotation.

```yaml
annotations:
  command: &cmd sysbench --test=cpu --time=10800 --cpu-max-prime=1000 --threads=1 run
```

The default execution time is 3 hours.

While sysbench is running, it uses all the pod's specified resource limits. Therefore, please check the host node's resource status and change the resource limit accordingly.

```yaml
resources:
  limits:
    memory: "128Mi"
    cpu: "500m"
```

If you are using a host node other than Oracle Cloud Free Tier, you need to specify nodeAffinity.

```yaml
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
      - key: topology.kubernetes.io/zone
        operator: In
        values:
          - "jp"
```

### Using Cronjob

To change the start time, adjust the following item.

```yaml
schedule: "0 3 * * *"
```

I run sysbench every day at 3 AM.

Since a cronjob cannot reserve a job for all pods like daemonsets, you need to modify the following items according to the number of nodes.

```yaml
parallelism: 6
completions: 6
```

This value must match the number of nodes. If it is too small, some nodes will not run, and if it is too large, sysbench will be executed redundantly.

### Note
You can use Oracle Cloud Free Tier without encountering this problem if you register PAYG or switch to a paid account and pay only the storage cost of 200 YEN.

If you're people enough to find and apply this solution, you might be better off saving a cup of coffee and investing that money in a solution. (But I drank coffee with that money :wink:)