# pxe-cookbook

PXE Configuration and Kickstart for Centos 6/7 servers.
This cookbook is largely based on pxe_dust by Matt Ray

## Supported Platforms

RHEL 6/7
CentOS 6/7

## Attributes

## Usage

### pxe::default

Include `pxe` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[pxe::default]"
  ]
}
```

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-new-recipe`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Author:: UAF-GINA (<support+chef@gina.alaska.edu>)
