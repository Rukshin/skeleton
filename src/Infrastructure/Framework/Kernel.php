<?php

namespace Infrastructure\Framework;

use Symfony\Component\Config\Loader\LoaderInterface;
use Symfony\Component\Config\Resource\FileResource;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\HttpKernel\Kernel as BaseKernel;
use function array_merge;
use function dirname;

final class Kernel extends BaseKernel
{
    public function registerBundles(): iterable
    {
        $require = static function(string $fileName): iterable {
            yield from require $fileName;
        };

        $contents = $require($this->getConfigDir() . '/bundles.php');

        foreach ($contents as $class => $envs) {
            if ($envs[$this->environment] ?? $envs['all'] ?? false) {
                yield new $class();
            }
        }
    }

    public function registerContainerConfiguration(LoaderInterface $loader): void
    {
        $loader->load(function (ContainerBuilder $container) use ($loader) {
            $this->configureContainer($container, $loader);

            $container->addObjectResource($this);
        });
    }

    public function getProjectDir(): string
    {
        return dirname(__DIR__, 3);
    }

    public function getConfigDir(): string
    {
        return $this->getProjectDir() . '/config';
    }

    protected function getKernelParameters(): array
    {
        return array_merge(parent::getKernelParameters(), [
            'kernel.src_dir' => $this->getProjectDir() . '/src',
            'kernel.config_dir' => $this->getConfigDir(),
            'kernel.resources_dir' => $this->getProjectDir() . '/resources',
        ]);
    }

    private function configureContainer(ContainerBuilder $container, LoaderInterface $loader): void
    {
        $configDir = $this->getConfigDir();
        $container->addResource(new FileResource($configDir . '/bundles.php'));

        $loader->load($configDir . '/services.yaml');
        $loader->load($configDir . '/{services}/*.yaml', 'glob');
        $loader->load($configDir . '/services_' . $this->environment . '.yaml');
        $loader->load($configDir . '/{packages}/*.yaml', 'glob');
        $loader->load($configDir . '/{packages}/' . $this->environment . '/**/*.yaml', 'glob');

        $require = static function(string $fileName) use ($container): void {
            $container->addResource(new FileResource($fileName));

            $builder = require $fileName;
            $builder($container);
        };

        $require($configDir . '/build.php');
    }
}
