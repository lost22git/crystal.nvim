# crystal.nvim

## Installation

- lua

```lua
{"lost22git/crystal.nvim", lazy=false, config=true}
```

- fennel

```fennel
{1 "lost22git/crystal.nvim" :lazy false :config true}
```

## Default Keymaps

|mode|key|function| demo |
|:----|:----|:----|:----:|
| n | \<Leader>kc | crystal tool context | ![tool-context](./demo/tool-context.jpg) |
| n | \<Leader>ke | crystal tool expand | ![tool-context](./demo/tool-expand.jpg) |
| n,v | \<Leader>kh | crystal tool hierarchy | ![tool-hierarchy](./demo/tool-hierarchy.jpg) |
| n | \<Leader>ki| crystal tool implementations | ![tool-implementations](./demo/tool-implementations.gif) |
| n,v | \<Leader>kk | docr tree | ![docr-tree](./demo/docr-tree.jpg) |
| n,v | \<Leader>k | docr info | ![docr-info](./demo/docr-info.jpg) |
| n,v | \<Leader>K | docr search | ![docr-search](./demo/docr-search.jpg) |
